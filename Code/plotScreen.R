library(data.table)
library(ggplot2)
library(RColorBrewer)
library(dplyr)
library(scales)
library(tidyr)
library(viridis)


args = commandArgs(trailingOnly=TRUE)

if (length(args) != 3) {
  stop("This should contain on <output.plot.from.rule.parse.txt> <mapping.txt> <file.pdf>", call.=FALSE)
}

#Testing purposes only 
#args = c("../Processed_data/tester2plot.txt","../Sandbox/concentrations.csv","test.screen.pdf")


data <- fread(args[1],header=T,sep="\t")
mymap <- fread(args[2],header=F,sep=",")

data$AVG = rowMeans(data[,4:7])

drugs = mymap[which(grepl("d_",mymap$V1)),]
colnames(drugs) = c("dID","Drug")
concen = mymap[which(grepl("v_",mymap$V1)),]
colnames(concen) <- c("vID","Concentrations")


data = data %>% tidyr::separate(DrugVol, c("dID","vID"), "_v")
data$vID = paste("v",data$vID,sep="")


#Now merge the information of the drug and concentations onto this file 
wDrug <- merge(data,drugs,by="dID")
wConc <- merge(wDrug,concen,by="vID")

wConc$Concentrations = factor(wConc$Concentrations, levels=rev(concen$Concentrations))
wConc$Drug = factor(wConc$Drug, levels=drugs$Drug)

#Now if I can take this and make a tile plot I should be good 
solv <- wConc[which(wConc$Normalized == "Solvent"),]
colfunc <- colorRampPalette(c("red","white","green"))

p <- ggplot(solv,aes(x=Drug,y=Concentrations))
p <- p + geom_tile(aes(fill = AVG))
p <- p + facet_wrap(~ Plate)
p <- p + theme_classic() 
p <- p + theme(axis.text.x = element_text(angle = 90, hjust=1,vjust=.5))
#p <- p + scale_fill_viridis(limits = c(0,4))
#p <- p + scale_fill_gradient2(high="red", mid="white", low="green", midpoint = 1, limits = c(0,4))
p <- p + scale_fill_gradientn(colours = colfunc(3), limits=c(-0.1,4), values=rescale(c(-0.1,1,4)))
#p

pdf(args[3],height=6,width=8)
print(p)
dev.off()

