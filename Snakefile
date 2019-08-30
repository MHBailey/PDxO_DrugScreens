configfile: 'TOW19B6_1.yaml'

from pathlib import Path

DP = Path(config['RETRO']).parent.name
DN = Path(config['RETRO']).name
print("Working on "+DP)
#print("Working on "+DP)
DPN = DP+'/'+DN

rule parse:
    input:
        blank=config['BLANK'],
        retro=config['RETRO'],
        mymap=config['MAP'],
        parse='Code/parseScreenNoAdj.py'
    output: 
        toPlot='Processed_data/'+DPN+'_transformed.txt'
    shell:
        '''
        touch {output.toPlot}
        rm {output.toPlot}
        touch {output.toPlot}
        python {input.parse} {input.blank} {input.retro} {input.mymap} {output.toPlot}
        '''


rule analyze: 
    input:
        toPlot='Processed_data/'+DPN+'_transformed.txt',
        mymap=config['MAP'],
        plot='Code/plotScreenPlate.R'
    output:
        sPlot='Processed_data/'+DPN+'_results.pdf'
        sPlot='Processed_data/'+DPN+'_results.pdf',
        dPlot='Processed_data/'+DPN+'_results_bydrug.pdf',
        longf='Processed_data/'+DPN+'.longformat.txt'
    shell:
        '''
        Rscript --quiet --vanilla {input.plot} {input.toPlot} {input.mymap} {output.sPlot} {output.longf} {output.dPlot}
        '''    


rule calc_ecStatic_noAVG:
    input:
        katmatt='Processed_data/'+DPN+'.longformat.txt',
        katECscript='Code/katECstatic_noAVG.R'
    output:
        ecstatic='Processed_data/'+DPN+'_ecstats.txt' 
    shell:
        '''
        Rscript --quiet --vanilla {input.katECscript} {input.katmatt} {output.ecstatic}
        '''

rule all: 
    input: 'Processed_data/'+DPN+'_results.pdf'
    input: 
        figures='Processed_data/'+DPN+'_results.pdf',
        #ecstats='Processed_data/'+DPN+'_ecstats.txt'




