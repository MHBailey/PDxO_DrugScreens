library(data.table)
library(ggplot2)
library(RColorBrewer)
library(dplyr)
library(scales)
library(tidyr)
library(viridis)
library(stringr)
library(reshape2)


args = commandArgs(trailingOnly=TRUE)

if (length(args) != 5) {
  stop("This should contain on <output.rule.parse> <mapping.txt> <file.pdf> <ouput.to.longformat>", call.=FALSE)
}

#Testing purposes only 
#args = c("Processed_data/20190830_TowardsNew/toxi2day6.csv_transformed.txt","/Users/mbailey/Desktop/UTAH/HCI/PDxO_Pipeline/PDxO_DrugScreens/Data/20190830_TowardsNew/concentrations_1.csv","Processed_data/20190830_TowardsNew/toxi2day6.csv_results.pdf","Processed_data/20190830_TowardsNew/toxi2day6.csv.longformat.txt")


data <- fread(args[1],header=T,sep="\t")
mymap <- fread(args[2],header=F,sep=",")

data$AVG = rowMeans(data[,4:7])

drugs = mymap[which(grepl("d_",mymap$V1)),]
colnames(drugs) = c("dID","Drug")
concen = mymap[which(grepl("v_",mymap$V1)),]
colnames(concen) <- c("vID","Concentrations")
plates = mymap[which(grepl("Plate_",mymap$V1)),]
colnames(plates) <- c("pID","Sample")

data = data %>% tidyr::separate(DrugVol, c("dID","vID"), "_v")
data$PD = paste(data$Plate,data$dID,sep="_")
data$vID = paste("v",data$vID,sep="")

#Add the sample names to this plot



#Now merge the information of the drug and concentations onto this file 
wPlate <- merge(data,plates,by.x="Plate",by.y="pID")
wDrug <- merge(wPlate,drugs,by.x="dID",by.y="dID")
wConc <- merge(wDrug,concen,by="vID")

#This little section will create the data in the long format so that I can calculate ecstatic, so I'm going to match the data in form that I used for the KAT_EC and move from there. 
sampname <- strsplit(args[1],"/")[[1]][2]
newConc <- wConc
newConc$Vol = as.numeric(str_remove(newConc$Concentrations,"uM"))
myTemp <- newConc[,c("Plate","Drug","Vol","Normalized","V1","V2","V3","V4")]
myTemp$Plate = paste(sampname,myTemp$Plate,sep="_")

myLong <- melt(myTemp,id.vars=c("Plate","Drug","Vol","Normalized"))
colnames(myLong) <- c("Plate","Drug","Vol","Normalized","Variable","Value")

myLong$DrugSet = sampname
myLong$Drug = tolower(myLong$Drug)
write.table(myLong, args[4], quote=F, sep="\t", row.names=F)



wConc$Concentrations = factor(wConc$Concentrations, levels=rev(concen$Concentrations))
wConc$Drug = factor(wConc$Drug, levels=drugs$Drug) #NOTE: not sure why I need this line? 

#Now if I can take this and make a tile plot I should be good 
solv <- wConc[which(wConc$Normalized == "Solvent"),]
colfunc <- colorRampPalette(c("red","white","green"))
print(head(solv))
p <- ggplot(solv,aes(x=Drug,y=Concentrations))
p <- p + geom_tile(aes(fill = AVG))
p <- p + facet_wrap(~ Sample,scales="free_x")
p <- p + theme_classic() 
p <- p + theme(axis.text.x = element_text(angle = 90, hjust=1,vjust=.5))
p <- p + scale_fill_gradientn(colours = colfunc(3), limits=c(-0.1,4), values=rescale(c(-0.1,1,4)))
#p

pdf(args[3],height=6,width=8)
print(p)
dev.off()



p <- ggplot(solv,aes(x=Sample,y=Concentrations))
p <- p + geom_tile(aes(fill = AVG))
p <- p + facet_wrap(~ Drug,scales="free_x")
p <- p + theme_classic()
p <- p + theme(axis.text.x = element_text(angle = 90, hjust=1,vjust=.5))
p <- p + scale_fill_gradientn(colours = colfunc(3), limits=c(-0.1,4), values=rescale(c(-0.1,1,4)))
pdf(args[5],height=6,width=8)
print(p)
dev.off()






