def getLineCNV(fname,var):
    out = 0
    with open(fname, "r") as f:
        for line in f:
            variable,value = line[:-1].split(",")
            if variable == var:
                out = value
    f.close()
    return out  

def dictPrint(d):
    for k in d:
        print(k+": "+str(d[k]))


def processBlank(BLANK):
    rownames = [x[0] for x in BLANK.keys()]
    colnames = [int(x[1:]) for x in BLANK.keys()]
    rownames.sort()
    colnames.sort()
    rows = sorted(set(rownames))
    cols = sorted(set(colnames))
    
    
    #This little step will cut out columns with no info. 
    lastR = rows[len(rows)-1]
    colstrim=[]
    for c in cols:
        bk = lastR+str(c)
        if BLANK[bk] != "":
            colstrim.append(c)
    

    #This chunk of code goes through BLANK two columns at a time 
    #in order to calculate averages Day0 averages per plate. 
    D0averages = []
    counts = 0
    pairs = True
    d0platesum = 0
    for c in colstrim:
        for r in rows:
            counts += 1
            bk = r+str(c)
            d0platesum += float(BLANK[bk])
        
        if pairs:
            pairs = False
        else:
            if counts > 0:
                avg = d0platesum/counts
                D0averages.append(avg)
            pairs = True 
            d0platesum = 0
            counts = 0            

    print(colstrim)
    return(D0averages) 


def processRetro(RETRO):
    rownames = [x[0] for x in RETRO.keys()]
    colnames = [int(x[1:]) for x in RETRO.keys()]
    rownames.sort()
    colnames.sort()
    rows = sorted(set(rownames))
    cols = sorted(set(colnames))[1:]
   
    lastR = rows[len(rows)-1]
    colstrim=[]
    for c in cols:
        rk = lastR+str(c)
        if RETRO[rk] != "":
            colstrim.append(c)
     
    SCREEN = {}

    number = 0
    drug = False
    first = False
    for c in colstrim:
        concentration = 0
        if drug:
            drug = False
        else:
            number += 1
            drug = True

        for r in rows:
            k = r+str(c)
            v = RETRO[k]
            if first:
                first = False
            else:
                concentration += 1
                first = True

            #Conditions and placeing 
            skey = "d_"+str(number)+"_v_"+str(concentration)
            if drug and first:
                SCREEN[skey] = [v,0,0,0]
            elif drug and not first:
                SCREEN[skey][1] = v
            elif not drug and first:
                SCREEN[skey][2] = v
            elif not drug and not first:
                SCREEN[skey][3] = v

    return SCREEN

def processPlate(BLANK, RETRO, group, out, blankMOD):
    #I'm at the point where I need to calculate averages from BLANKS and SOLVENT
    D0MOD = blankMOD 
    D0avgs = processBlank(BLANK)
    d0platepos = int(group/D0MOD) #This catptures which blank to pull
    print("Processing plate #: "+str(group))

    try:
        d0avg = D0avgs[d0platepos]
    except IndexError:
        print('\n\nWARNING:::Emilio is VERY ANGRY WITH YOU!!!!!\nYou DO NOT have enough blanks to cover the rest of the plates.\nPlease check the PlatesPerBlank (MOD) command in concentrations.csv.\n\nThe program with continue with the blanks you specified.\nNow go apologize to Emilio and fix the concentration.csv file\n\n\n')
        sys.exit(0)

    d0avg = D0avgs[d0platepos] #Array position of the 

    #Get the plate information
    PLATE = processRetro(RETRO)
    SOLVE = {}
    D0NORM = {}

    #Calculate solvent avg. 
    solventAvg = 0
    solventSum = 0
    solventCnt = 0

    if PLATE["d_1_v_1"]  != '- ': #This just skips that empty tables 
        Solves = [x for x in PLATE.keys() if x.startswith("d_1_")] #HARD CODED for first "drug"
        for s in Solves:
            solventCnt += len(PLATE[s])
            solventSum += sum([float(x) for x in PLATE[s]])    
        solventAvg = solventSum/solventCnt

        for k in PLATE:
            SOLVE[k] = [float(x)/solventAvg for x in PLATE[k]]
            D0NORM[k] = [float(x)/d0avg for x in PLATE[k]]

    #Now I write out a file that can be dealt with in R 
    ofname = out
    with open(ofname, "a+") as o: 
        if len(PLATE["d_1_v_1"]) == 4 and group == 0:
            header = ["Plate","DrugVol","Normalized","V1","V2","V3","V4"] #THIS NEEDS TO BE LESS HARD CODED
            o.write("\t".join(header))
            o.write("\n")
        #else:
            #sys.exit("I am requiring 4 replicates")
        for k in PLATE:
            #Take care of RAW 
            out = []
            out.append("Plate_"+str(group)) #Identifiers
            out.append(k)
            out.append("Raw")
            out += PLATE[k]
            o.write("\t".join(out))
            o.write("\n")
            #Take care of SOLVENT Normalized 
            out = [] 
            out.append("Plate_"+str(group)) #Identifiers
            out.append(k)
            out.append("Solvent")
            out += [str(x) for x in SOLVE[k]]
            o.write("\t".join(out))
            o.write("\n")
            #Take care of the D0 Norm
            out = []
            out.append("Plate_"+str(group)) #Identifiers
            out.append(k)
            out.append("Day0")
            out += [str(x) for x in D0NORM[k]]
            o.write("\t".join(out))
            o.write("\n") 

           

def parseScreen(f1,f2,out,blankMOD,blankADJ):

    headstr = "10,11,12,13,14,15,16,17,18,19,20"
    empty = ",,,,,,,,,,,,,,,,,,,,,,,,"
    flag = False
    first = True 
    platenum = -1 #Starting this at -1 to get the MOD-like functionality in processPlate(,,group)

    BLANK = {}
    RETRO = {}
    
    with open(f1,"r") as f:
        for line in f: 
            if headstr in line[:-1]: #I could make this more dynamic by make this str.startswith
                flag = True

            if flag and (line[:-1] == empty or line == "\n"):
                flag = False
                break

            if flag and headstr not in line[:-1]:
                count = 0
                platerow = ""
                for i in line[:-1].split(","):
                    if count == 0:    
                        platerow = i 
                    else:
                        k = platerow+str(count) #this captures row and col 
                        BLANK[k] = i
                    count += 1
    f.close() 
    #dictPrint(BLANK)

 
    with open(f2, "r") as f:
        for line in f:
            if headstr in line[:-1]: 
                flag = True
            
            if blankADJ.lower() == "yes":
                if flag and (line[:-1] == empty or line == "\n"):
                    flag = False
                    if first:
                        platenum += 1   
                        if RETRO["A2"] != "- ":
                            processPlate(BLANK,RETRO,platenum,out,blankMOD)
                        RETRO = {} #Empty the old Retro 
                        first = False
                    else:
                        first = True

            else:
                if flag and (line[:-1] == empty or line == "\n"):
                    flag = False
                    platenum += 1
                    if RETRO["A2"] != "- ":
                        processPlate(BLANK,RETRO,platenum,out,blankMOD)
                    RETRO = {} #Empty the old Retro 

            if flag and first and headstr not in line[:-1]:
                count = 0 
                platerow = ""
                for i in line[:-1].split(","):
                    if count == 0:
                        platerow = i
                    else:
                        k = platerow+str(count) #this captures row and col 
                        RETRO[k] = i 
                    count += 1
        

                     
if __name__ == "__main__":
    import sys 
    f1 = sys.argv[1] #This is the BLANK
    f2 = sys.argv[2] #This is the Retro 
    blankMOD = int(getLineCNV(sys.argv[3],"MOD")) # Neets to be automated 
    blankADJ = getLineCNV(sys.argv[3],"ADJ") # is the file have adj or not
    out = sys.argv[4] # This is the output #Something to take to ggplot

    parseScreen(f1,f2,out, blankMOD, blankADJ)
