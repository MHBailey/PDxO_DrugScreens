configfile: 'config.yaml'

from pathlib import Path

DP = Path(config['RETRO']).parent.name
DN = Path(config['RETRO']).name
print("Working on "+DP)
DPN = DP+'/'+DN

rule parse:
    input:
        blank=config['BLANK'],
        retro=config['RETRO'],
        mymap=config['MAP'],
        parse='Code/parseScreen.py'
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
        plot='Code/plotScreen.R'
    output:
        sPlot='Processed_data/'+DPN+'_results.pdf'
    shell:
        '''
        Rscript --quiet --vanilla {input.plot} {input.toPlot} {input.mymap} {output.sPlot}
        '''    


rule all: 
    input: 'Processed_data/'+DPN+'_results.pdf'




