configfile: 'config.yaml'

from pathlib import Path


rule parse:
    input:
        blank=config['BLANK'],
        retro=config['RETRO'],
        blankmod=config['MOD'],
        parse='Code/parseScreen.py'
    output: 
        toPlot='Processed_data/tester2plot.txt'
    shell:
        '''
        touch {output.toPlot}
        rm {output.toPlot}
        touch {output.toPlot}
        python {input.parse} {input.blank} {input.retro} "{input.blankmod}" {output.toPlot}
        '''


rule analyze: 
    input:
        toPlot='Processed_data/tester2plot.txt',
        mymap=config['MAP'],
        plot='Code/plotScreen.R'
    output:
        sPlot='Processed_data/tester2plot.pdf'
    shell:
        '''
        Rscript --quiet --vanilla {input.plot} {input.toPlot} {input.mymap} {output.sPlot}
        '''    


rule all: 
    input: "Processed_data/tester2plot.pdf"




