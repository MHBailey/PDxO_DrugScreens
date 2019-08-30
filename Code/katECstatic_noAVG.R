library(data.table)
library(ggplot2)
library(RColorBrewer)
library(dplyr)
library(scales)
library(tidyr)
library(viridis)
library(drc)
library(reshape2)


f <- function(p) as.numeric(PR(mod2,p))
ecstat <- function(dat,mod) {

    beta = coef(mod)[1] #Beta
    bottom = coef(mod)[2] #Bottom
    top = coef(mod)[3] #Top
    flex = coef(mod)[4] #Flex
    
    ecstatic = NULL
    modelled = NULL
    #Calculate and chech ECSTATIC
 
    if(bottom < 1 && PR(mod,100000) < 1 && PR(mod,6.25e-07) > 1){
        z <- function(x, y, mod) y - predict(mod, data.frame(conc = x))[1]
        ecstatic <- as.numeric(unlist(uniroot(z, c(0, 100000), y = 1, mod)[1]))
        if(ecstatic < 100){
            modelled = "Modelled"
        }
        else{
            modelled = "Predicted"
        }
    }
    else{
        modelled = "NonConverged"
        ecstatic = -9
    }
    
    #Model measures
    GoF = cor(dat$Value,predict(mod)) #Goodness of fit
    e2 = dat$Value-predict(mod) #resids
    nlm_error = sqrt(mean(e2^2))
    
    #Plot the figures. 
    pdf(paste("Figures/Regression_ModelsV2/",e2flag,"_",s,"_",d,".pdf",sep=""),height=4,width=4,useDingbats=F)
    plot(mod,type="all")
    #lines(dat$Vol,predict(mod),col="red",lty=2,lwd=3)
    abline(h=1,v=ecstatic)
    dev.off()
    
    o = NULL
    #Keep track of the data
    if(modelled == "NonConverged"){ #Don't integrate with NA ecstatic
        o = data.frame("Plate" = s, "Drug" = d, "DrugSet" = rp, "ECstatic" = ecstatic, "respInt"=NA, "nonrInt" = NA, "nonrUnd" = NA, "GoodFit" = GoF, "Error"=nlm_error, "Beta"=beta, "Flex"=flex, "Bottom"=bottom, "Top"=top, "Modelled" = modelled)
    }
    else if(modelled == "Predicted"){
        o = data.frame("Plate" = s, "Drug" = d, "DrugSet" = rp, "ECstatic" = ecstatic, "respInt"=NA, "nonrInt" = NA, "nonrUnd" = NA, "GoodFit" = GoF, "Error"=nlm_error, "Beta"=beta, "Flex"=flex, "Bottom"=bottom, "Top"=top, "Modelled" = modelled)
    }
    else{
        z <- function(x, y, mod2) y - predict(mod2, data.frame(conc = x))[1]
        mod2 <- checkMod(dat$Value, dat$Con) 
        if(is.null(mod2)){
            o = data.frame("Plate" = s, "Drug" = d, "DrugSet" = rp, "ECstatic" = ecstatic, "respInt"= NA, "nonrInt" = NA, "nonrUnd" = NA, "GoodFit" = GoF, "Error"=nlm_error, "Beta"=beta, "Flex"=flex, "Bottom"=bottom, "Top"=top, "Modelled" = modelled)
        }
        else if(PR(mod2,19) < 1 && PR(mod2,0) > 1){
            ecstatic2 <- as.numeric(unlist(uniroot(z, c(0, 10000), y = 1, mod2)[1]))
            f <- function(p) as.numeric(PR(mod2,p))
            n = integrate(f, min(dat$Con), ecstatic2)$value - ecstatic2
            r = max(dat$Con)-ecstatic2 - integrate(f, ecstatic2, max(dat$Con))$value
            u = integrate(f, ecstatic2, max(dat$Con))$value
            o = data.frame("Plate" = s, "Drug" = d, "DrugSet" = rp, "ECstatic" = ecstatic, "respInt"=r, "nonrInt" = n, "nonrUnd" = u, "GoodFit" = GoF, "Error"=nlm_error, "Beta"=beta, "Flex"=flex, "Bottom"=bottom, "Top"=top, "Modelled" = modelled)
        }
        else{
            o = data.frame("Plate" = s, "Drug" = d, "DrugSet" = rp, "ECstatic" = ecstatic, "respInt"= NA, "nonrInt" = NA, "nonrUnd" = NA, "GoodFit" = GoF, "Error"=nlm_error, "Beta"=beta, "Flex"=flex, "Bottom"=bottom, "Top"=top, "Modelled" = modelled)
        }
    }
    return(o)
}

checkMod <- function(Value, Vol) {
    mod <- tryCatch(
        {
           out <- NULL
           out <- drm(Value ~ Vol, fct=LL.4())
        }, error = function(e) {
           print(paste("MY_ERROR: DID NOT CONVERGE with drc\n", e))
           return(NULL)
        }, finally = {
           return(out)
        }
    )
    return(mod)
}
 

args = commandArgs(trailingOnly=TRUE)

if (length(args) != 2) {
  stop("This should contain on <formatted.drugscreen> <output.name>", call.=FALSE)
}

#Testing purposes only 
#args <- c("Processed_data/TOW19/day6i1.csv.longformat.txt","Processed_data/TOW19/day6i1.csv_ecstats.txt")

data <- fread(args[1],header=T,sep="\t")
#data$AVG = rowMeans(data[,c('V1','V2','V3','V4')],na.rm=T)

#Capture the run
fname <- unlist(strsplit(args[2],"[/]"))[3]
e2flag <- unlist(strsplit(fname,"[.]"))[1]

#Now merge the information of the drug and concentations onto this file 
d0 <- data[which(data$Normalized == "Day0"),]

#Interate over these 
samples = unique(d0$Plate)
ECSTATIC = NULL 

#samples = c("TOW19_Plate_2")
#s = samples

for(s in samples){ #sample and plate
    sp = d0[which(d0$Plate == s),]
    drugs = unique(sp$Drug)
    #drugs = "vinblastine"
    #d = drugs
    for(d in drugs){#drug
        thisdrug = NULL
        dd <- sp[which(sp$Drug == d),]
        drugset = unique(dd$DrugSet)
        #rp = "TOW19"
        for(rp in drugset){
            dat <- dd[which(dd$DrugSet == rp),]
            #plot(factor(dat$Vol),dat$Value)
	    print(c(s,d))
            mymin <- min(dat[which(dat$Value > 0),]$Value)
            mymin <- ifelse(mymin < 0.001, mymin, 0.001) #set min
            #NOTE: THIS HAS TO CHANGE
            dat$Vol <- ifelse(dat$Vol == 0,)
            dat$Value <- ifelse(dat$Value < 0, mymin, dat$Value)#This will remove negative values... 
            print(paste(dat$Value,collapse=","))
            print(paste(dat$Vol,collapse=","))
            dat$Con = log(dat$Vol) + (-1*min(log(dat$Vol)))
            mod <- checkMod(dat$Value, dat$Vol)
            print(mod)
            if(is.null(mod)){
                thisdrug = data.frame("Plate" = s, "Drug" = d, "DrugSet" = rp, "ECstatic"=NA, "respInt"=NA, "nonrInt" = NA, "nonrUnd" = NA, "GoodFit" = NA, "Error"=NA, "Beta"=NA, "Flex"=NA, "Bottom"=NA, "Top"=NA, "Modelled" = NA)
                    pdf(paste("Figures/Regression_ModelsV2/",e2flag,"_",s,"_",d,".pdf",sep=""),height=4,width=4,useDingbats=F)
                    plot(factor(dat$Vol),dat$Value)
                    points(factor(dat$Vol),dat$Value)
                    abline(h=1)
                    dev.off()
            }else{
                thisdrug <- ecstat(dat,mod)
            }
            ECSTATIC <- rbind(ECSTATIC,thisdrug)
        }
    }
}

write.table(ECSTATIC,args[2],sep="\t",quote=F, row.names = F)

