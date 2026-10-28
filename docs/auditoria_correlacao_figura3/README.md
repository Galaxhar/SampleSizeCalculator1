# Reconstrução exploratória da Figura 3

Estes dados são **coordenadas de um gráfico publicado, não os dados originais dos participantes**. As correlações são cálculos novos e não coeficientes informados por Freire et al. (2007). Não foram adotadas no dimensionamento do ensaio. Ver as limitações em [revisao_metodologica_pendente.md](../revisao_metodologica_pendente.md).

Fonte: `references/original/freire_2007.pdf`, página impressa 48 (sexta página do PDF), Figura 3. O hash da fonte, os índices dos desenhos vetoriais e a calibração dos eixos estão em `extraction_metadata.json`. O arquivo `freire2007_figure3_pairs.csv` preserva cada segmento pareado completo; as linhas que se cruzam não exigiram inferir a correspondência dos pontos.

Para reproduzir a extração, na raiz do repositório:

```sh
python docs/auditoria_correlacao_figura3/extract_freire_figure3.py
```

Essa etapa opcional usa PyMuPDF (`fitz`; versão utilizada: 1.26.6), disponível no ambiente desta revisão. Não é dependência do cálculo amostral em R. Para recalcular as correlações diretamente do CSV, sem essa dependência:

```sh
/workspace/tooling/bin/Rscript --vanilla docs/auditoria_correlacao_figura3/analyze_freire_figure3.R
```

O R calcula as correlações por grupo e os IC95% aproximados de Fisher, além da correlação dos 17 pares acupuntura–sham após centralização separada por braço e conversão dos painéis para eventos/h (r = 0,453201). Os intervalos não incorporam erro gráfico, seleção dos concluintes ou transportabilidade ao ensaio proposto.
