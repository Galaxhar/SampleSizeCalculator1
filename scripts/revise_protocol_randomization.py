"""Create a PARTIAL protocol revision, preserving other DOCX parts verbatim.

Only the randomization paragraph is replaced and two references are added.
The sample-size text remains pending an evidence-based decision on correlation.
Uses lxml; run from any directory. The uploaded original is never overwritten.
"""
from copy import deepcopy
from pathlib import Path
from zipfile import ZipFile
from lxml import etree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "references/original/projeto.docx"
TARGET = ROOT / "docs/projeto_randomizacao_revisao_parcial.docx"
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W}

TITLE = "Randomização e sigilo da alocação"
TEXTS = [
    "A sequência de alocação será gerada em R por pesquisador independente, sem participação no recrutamento, na aplicação das intervenções ou na avaliação dos desfechos, na razão 1:1, com estratificação por sexo e gravidade basal da AOS (leve: IAH ≥ 5 e < 15 eventos/h; moderada: IAH ≥ 15 e < 30 eventos/h), utilizando blocos permutados de tamanhos variáveis. Os tamanhos dos blocos, o código, a semente e a sequência completa serão definidos e arquivados antes do início do recrutamento, sob acesso restrito ao responsável pela randomização. A estratificação e os blocos favorecem o equilíbrio entre os grupos nos fatores prognósticos especificados; a variação dos tamanhos e sua não divulgação à equipe de recrutamento reduzem a previsibilidade das próximas atribuições (Schulz e Grimes, 2002b).",
    "A alocação será centralizada nesse pesquisador independente. Após assinatura do termo de consentimento, confirmação da elegibilidade e conclusão e registro das avaliações basais, a equipe solicitará a alocação mediante identificador único e estrato do participante. O responsável liberará a próxima atribuição disponível no respectivo estrato exclusivamente à médica que executará a intervenção, sem revelar alocações futuras. Serão registrados identificador, estrato, data e hora da solicitação e da liberação, grupo atribuído e responsável, em controle de acesso restrito, separado dos registros utilizados pelos avaliadores cegos. Atribuições realizadas não serão alteradas nem reutilizadas. Esse procedimento visa impedir o conhecimento antecipado da intervenção no momento de decidir a inclusão, reduzindo o risco de viés de seleção; o cegamento dos participantes e avaliadores será mantido conforme os procedimentos das intervenções (Schulz e Grimes, 2002a).",
]
REFERENCES = [
    "Schulz KF, Grimes DA. Allocation concealment in randomised trials: defending against deciphering. Lancet. 2002a;359:614–618. doi:10.1016/S0140-6736(02)07750-4.",
    "Schulz KF, Grimes DA. Generation of allocation sequences in randomised trials: chance, not choice. Lancet. 2002b;359:515–519. doi:10.1016/S0140-6736(02)07683-3.",
]


def plain(p):
    return "".join(p.xpath(".//w:t/text()", namespaces=NS))


def paragraph(text, template, heading=False):
    p = ET.Element(f"{{{W}}}p")
    props = template.find("w:pPr", NS)
    if props is not None:
        props = deepcopy(props)
        if heading:
            # Keep the existing section numbering; references retain their list.
            for unwanted in props.findall("w:numPr", NS):
                props.remove(unwanted)
            for name in ["jc", "ind"]:
                for element in props.findall(f"w:{name}", NS):
                    props.remove(element)
            ET.SubElement(props, f"{{{W}}}jc", {f"{{{W}}}val": "left"})
            if props.find("w:keepNext", NS) is None:
                ET.SubElement(props, f"{{{W}}}keepNext")
        p.append(props)
    run = ET.SubElement(p, f"{{{W}}}r")
    rp = ET.SubElement(run, f"{{{W}}}rPr")
    ET.SubElement(rp, f"{{{W}}}rFonts", {f"{{{W}}}ascii": "Arial", f"{{{W}}}hAnsi": "Arial"})
    if heading:
        ET.SubElement(rp, f"{{{W}}}b")
    ET.SubElement(rp, f"{{{W}}}sz", {f"{{{W}}}val": "24"})
    ET.SubElement(rp, f"{{{W}}}highlight", {f"{{{W}}}val": "yellow"})
    ET.SubElement(run, f"{{{W}}}t").text = text
    return p


with ZipFile(SOURCE) as zin:
    raw = zin.read("word/document.xml")
    doc = ET.fromstring(raw)
    body = doc.find("w:body", NS)
    ps = body.findall("w:p", NS)
    old = [p for p in ps if plain(p).startswith("A sequência de randomização será gerada por método computacional")]
    population = [p for p in ps if plain(p).strip() == "População do estudo"]
    assert len(old) == len(population) == 1
    # Original text is nested in a content control; remove the whole paragraph.
    original_others = [ET.tostring(p) for p in ps if p is not old[0]]
    body.remove(old[0])
    insertion = body.index(population[0])
    added = [paragraph(TITLE, ps[69], heading=True)]
    added += [paragraph(s, ps[70]) for s in TEXTS]
    for offset, element in enumerate(added):
        body.insert(insertion + offset, element)
    # References are author/date, in order of citation groups in the source.
    reference_template = ps[225]
    reference_location = body.index(ps[295])
    added_refs = [paragraph(s, reference_template) for s in REFERENCES]
    for offset, element in enumerate(added_refs):
        body.insert(reference_location + offset, element)
    added_ids = {id(p) for p in added + added_refs}
    assert [ET.tostring(p) for p in body.findall("w:p", NS) if id(p) not in added_ids] == original_others
    for p in added + added_refs:
        for run in p.findall("w:r", NS):
            assert run.find("w:rPr/w:highlight", NS).get(f"{{{W}}}val") == "yellow"
    modified = ET.tostring(doc, encoding="UTF-8", xml_declaration=True, standalone=True)
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(TARGET, "w") as zout:
        for member in zin.infolist():
            zout.writestr(member, modified if member.filename == "word/document.xml" else zin.read(member.filename))

with ZipFile(SOURCE) as zin, ZipFile(TARGET) as zout:
    assert zout.testzip() is None
    assert zin.namelist() == zout.namelist()
    for name in zin.namelist():
        if name != "word/document.xml":
            assert zin.read(name) == zout.read(name), name
    revised = ET.fromstring(zout.read("word/document.xml"))
    all_text = "\n".join(plain(p) for p in revised.find("w:body", NS).findall("w:p", NS))
    assert all_text.count(TITLE) == 1
    assert "A sequência de randomização será gerada por método computacional" not in all_text
print(TARGET)
print("Validated: 5 added paragraphs highlighted yellow; other paragraphs and ZIP parts preserved.")
print("PARTIAL revision: original sample-size passages still require replacement.")
