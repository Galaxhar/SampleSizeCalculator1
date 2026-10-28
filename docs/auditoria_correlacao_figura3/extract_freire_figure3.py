"""Extract vector line endpoints from Freire2007 Fig3, p48. No image inference.
Each selected line spans the Baseline and 12week x coordinates, retaining pairing.
Output points are FIGURE-DERIVED approximations, not original individual data.
"""
import csv,hashlib,fitz,json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
pdf=root/'references/original/freire_2007.pdf'
out=Path(__file__).resolve().parent
p=fitz.open(pdf)[5]
specs=[('acupuntura',2,135.24899,226.134,184.92999,84.24701,35,10),('controle',24,135.24899,226.134,318.60898,217.92596,70,9),('sham',45,136.57201,229.78101,457.26999,353.659,45,7)]
rows=[]
for group,index,x0,x1,yzero,ymax,maxvalue,expected in specs:
    pairs=[]
    for item in p.get_drawings()[index]['items']:
        if item[0]=='l' and abs(item[1].x-x0)<.01 and abs(item[2].x-x1)<.01:
            a,b=item[1],item[2]
            pairs.append(dict(group=group,pair=len(pairs)+1,x_baseline=a.x,y_baseline=a.y,x_post=b.x,y_post=b.y,
                ahi_baseline_figure=(yzero-a.y)/(yzero-ymax)*maxvalue,ahi_post_figure=(yzero-b.y)/(yzero-ymax)*maxvalue))
    assert len(pairs)==expected,(group,len(pairs),expected)
    rows+=pairs
with (out/'freire2007_figure3_pairs.csv').open('w') as f:
    w=csv.DictWriter(f,rows[0].keys(),lineterminator='\n');w.writeheader();w.writerows(rows)
(out/'extraction_metadata.json').write_text(json.dumps({'pdf_sha256':hashlib.sha256(pdf.read_bytes()).hexdigest(),'page_zero_based':5,'printed_page':48,'figure':3,'pymupdf_version':fitz.VersionBind,'method':'direct extraction of full paired line endpoints; linear axis calibration endpoints; Pearson correlation invariant to common affine axis calibration','group_specs':specs},indent=2))
print('Extracted',len(rows),'paired lines; exact expected counts 10+9+7 confirmed.')
