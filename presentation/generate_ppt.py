from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from xml.sax.saxutils import escape

OUT = Path(__file__).with_name('Kubernetes_Workload_Reliability.pptx')
W, H = 12192000, 6858000
BG, CARD, WHITE, MUTED = '0A1020', '121B2E', 'F7FAFC', '9DABC0'
ORANGE, CYAN, GREEN, PINK, YELLOW = 'FF8A3D', '45D7E8', '65D69C', 'F36D8D', 'F7C95D'
ID = 10


def col(c):
    return f'<a:solidFill><a:srgbClr val="{c}"/></a:solidFill>'


def textbox(text, x, y, w, h, size=18, c=WHITE, bold=False, align='l'):
    global ID
    ID += 1
    ps = []
    for raw in str(text).split('\n'):
        bullet, line = ('<a:buChar char="•"/>', raw[2:]) if raw.startswith('• ') else ('', raw)
        ps.append(f'<a:p><a:pPr algn="{align}">{bullet}</a:pPr><a:r><a:rPr lang="en-US" sz="{size*100}" b="{str(bold).lower()}">{col(c)}<a:latin typeface="Aptos"/></a:rPr><a:t>{escape(line)}</a:t></a:r><a:endParaRPr lang="en-US" sz="{size*100}"/></a:p>')
    return f'<p:sp><p:nvSpPr><p:cNvPr id="{ID}" name="Text {ID}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="{x}" y="{y}"/><a:ext cx="{w}" cy="{h}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></p:spPr><p:txBody><a:bodyPr wrap="square"/><a:lstStyle/>{"".join(ps)}</p:txBody></p:sp>'


def box(x, y, w, h, fill=CARD, border='23304A', geom='roundRect'):
    global ID
    ID += 1
    return f'<p:sp><p:nvSpPr><p:cNvPr id="{ID}" name="Box {ID}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="{x}" y="{y}"/><a:ext cx="{w}" cy="{h}"/></a:xfrm><a:prstGeom prst="{geom}"><a:avLst/></a:prstGeom>{col(fill)}<a:ln w="10000">{col(border)}</a:ln></p:spPr></p:sp>'


def bar(x, y, w, h, fill):
    return box(x, y, w, h, fill, fill, 'rect')


def dot(x, y, d, fill):
    global ID
    ID += 1
    return f'<p:sp><p:nvSpPr><p:cNvPr id="{ID}" name="Dot {ID}"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="{x}" y="{y}"/><a:ext cx="{d}" cy="{d}"/></a:xfrm><a:prstGeom prst="ellipse"><a:avLst/></a:prstGeom>{col(fill)}<a:ln><a:noFill/></a:ln></p:spPr></p:sp>'


def card(title, body, x, y, w, h, accent=ORANGE, label='', body_size=15):
    return ''.join([box(x, y, w, h, CARD, '23304A'), bar(x, y, 85000, h, accent), textbox(label.upper(), x+180000, y+140000, w-300000, 210000, 10, accent, True), textbox(title, x+180000, y+430000, w-300000, 360000, 17, WHITE, True), textbox(body, x+180000, y+890000, w-300000, h-1050000, body_size, MUTED)])


def header(title, section, n):
    return ''.join([textbox(section.upper(), 650000, 330000, 3000000, 250000, 10, ORANGE, True), textbox(title, 650000, 650000, 10500000, 650000, 27, WHITE, True), textbox(f'{n:02d}', 11300000, 430000, 400000, 250000, 12, MUTED, True, 'r'), bar(650000, 1400000, 11000000, 18000, '23304A')])


def slide(content):
    return f'<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/>{box(0,0,W,H,BG,BG,"rect")}{dot(11000000,500000,900000,'10263A')}{dot(11190000,690000,400000,ORANGE)}{content}{textbox('KUBERNETES WORKLOAD RELIABILITY  /  DEVOPS MINI-PROJECT',650000,6570000,7000000,180000,9,'63758F',True)}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>'


def build():
    s = []
    s.append(slide(textbox('DEVOPS MINI-PROJECT',750000,950000,3500000,300000,12,ORANGE,True)+textbox('Kubernetes\nWorkload Reliability',750000,1550000,6500000,1550000,34,WHITE,True)+textbox('Resource pressure analysis with Prometheus and Grafana',780000,3450000,5800000,500000,19,MUTED)+textbox('Deploy  →  Monitor  →  Simulate  →  Detect  →  Recover',780000,4900000,7000000,500000,17,CYAN,True)+box(7900000,1600000,3000000,3600000,CARD,'23304A')+textbox('OBSERVABILITY LOOP',8200000,1850000,2400000,250000,11,ORANGE,True,'c')+dot(8600000,2550000,900000,ORANGE)+textbox('P',8850000,2720000,400000,400000,28,BG,True,'c')+dot(9750000,2900000,550000,CYAN)+textbox('G',9910000,3010000,250000,250000,16,BG,True,'c')+textbox('Prometheus  →  Grafana',8300000,4100000,2300000,300000,13,WHITE,True,'c')))
    s.append(slide(header('Why monitor beyond uptime?','The problem',2)+textbox('A workload can be “up” and still be unhealthy.',850000,1900000,7000000,550000,25,WHITE,True)+textbox('Reliability becomes visible when Kubernetes state, container pressure, and application behavior are viewed together.',850000,2600000,6500000,700000,18,MUTED)+card('Resource pressure','CPU saturation, memory growth, throttling, and OOM risk.',850000,4000000,3300000,1300000,ORANGE,'Signal')+card('User impact','HTTP errors, request volume, and response-time changes.',4450000,4000000,3300000,1300000,PINK,'Signal')+card('Recovery','Replica availability and Kubernetes reconciliation.',8050000,4000000,3300000,1300000,GREEN,'Signal')))
    s.append(slide(header('One clear objective','Aim',3)+textbox('Build a repeatable local lab that turns failure modes into observable signals.',850000,1900000,10000000,650000,24,WHITE,True)+card('01  Deploy','Two Node.js replicas with probes and resource boundaries.',850000,3300000,3300000,1450000,ORANGE,'Phase')+card('02  Observe','Prometheus scrapes app + Kubernetes metrics; Grafana visualizes.',4450000,3300000,3300000,1450000,CYAN,'Phase')+card('03  Learn','Inject controlled load, errors, and pod deletion; inspect recovery.',8050000,3300000,3300000,1450000,GREEN,'Phase')))
    s.append(slide(header('The system in one picture','Architecture',4)+textbox('Traffic and state converge in Prometheus; Kubernetes remains the control plane.',850000,1750000,9500000,400000,17,MUTED)+card('Browser / test traffic','Invoke-RestMethod\nlocalhost:8000',850000,2900000,2350000,1100000,ORANGE,'Input',14)+textbox('→',3350000,3200000,450000,300000,28,ORANGE,True,'c')+card('Node.js Service','/health  /metrics  /load',3900000,2900000,2350000,1100000,CYAN,'Workload',14)+textbox('→',6400000,3200000,450000,300000,28,CYAN,True,'c')+card('Prometheus','Scrape · query · alert',6950000,2900000,2350000,1100000,ORANGE,'Signal',14)+textbox('→',9450000,3200000,450000,300000,28,ORANGE,True,'c')+card('Grafana','Dashboard and trends',10000000,2900000,1500000,1100000,GREEN,'View',13)+card('Kubernetes controller','Deployment reconciles desired replicas and replaces deleted pods.',3900000,4800000,5600000,950000,GREEN,'Recovery',15)))
    s.append(slide(header('Tools with a job to do','Stack',5)+card('Docker Desktop','Local image build + Kubernetes runtime.',850000,1900000,3000000,1150000,CYAN,'Runtime')+card('Kubernetes','Deployments, Services, probes, limits, reconciliation.',4100000,1900000,3000000,1150000,ORANGE,'Control plane')+card('Node.js + Express','Synthetic workload and application metrics.',7350000,1900000,3000000,1150000,PINK,'Application')+card('Prometheus','Time series storage, PromQL, rule evaluation.',850000,3600000,3000000,1150000,ORANGE,'Collect')+card('Grafana','Dashboards for trends, pressure, and error rate.',4100000,3600000,3000000,1150000,GREEN,'Explain')+card('Helm + exporters','Monitoring stack, object state, and node metrics.',7350000,3600000,3000000,1150000,CYAN,'Install')))
    s.append(slide(header('Implementation: small files, clear contracts','Build',6)+card('Application','server.js\npackage.json\nDockerfile',850000,1900000,3000000,2200000,ORANGE,'app/',17)+card('Kubernetes','app.yaml\nservicemonitor.yaml\nalerts.yaml\ndashboard.yaml',4100000,1900000,3000000,2200000,CYAN,'k8s/',17)+card('Automation','build.ps1\ninstall-monitoring.ps1\ndeploy.ps1\nrun-experiments.ps1',7350000,1900000,3000000,2200000,GREEN,'scripts/',17)+textbox('The project is intentionally easy to inspect, run, and explain in a viva.',850000,5000000,9300000,450000,20,WHITE,True)))
    s.append(slide(header('Five signals, one reliability story','Metrics',7)+card('CPU % of limit','Resource pressure\ncontainer_cpu_usage_seconds_total',850000,1900000,3000000,1500000,ORANGE,'01',14)+card('Memory % of limit','Working set / memory limit\nOOM risk context',4100000,1900000,3000000,1500000,PINK,'02',14)+card('Pod restarts','Container restart counter\nWhat recovered?',7350000,1900000,3000000,1500000,YELLOW,'03',14)+card('HTTP request rate','Traffic shape by status\nWhat is the app doing?',2500000,4000000,3000000,1500000,CYAN,'04',14)+card('HTTP 5xx rate','Application failure signal\nWill the alert fire?',6100000,4000000,3000000,1500000,GREEN,'05',14)))
    s.append(slide(header('Dashboard design','Observe',8)+textbox('A compact view for a live demo: pressure on top, behavior below.',850000,1750000,8000000,350000,17,MUTED)+box(850000,2500000,9800000,3000000,'0F192B','263A56')+textbox('KUBERNETES WORKLOAD RELIABILITY',1100000,2700000,6000000,300000,12,WHITE,True)+card('CPU %','—  42%',1100000,3250000,2000000,850000,ORANGE,'LIVE',15)+card('Memory %','—  58%',3350000,3250000,2000000,850000,PINK,'LIVE',15)+card('5xx / sec','—  0.0',5600000,3250000,2000000,850000,GREEN,'LIVE',15)+card('Restarts','—  0',7850000,3250000,2000000,850000,CYAN,'LIVE',15)+bar(1100000,4550000,9000000,20000,'29405A')+textbox('[ Replace with actual Grafana screenshot after deployment ]',2200000,4800000,7000000,400000,16,MUTED,True,'c')))
    s.append(slide(header('Demo path: from baseline to recovery','Experiments',9)+textbox('Each step creates one observable change.',850000,1750000,6500000,350000,17,MUTED)+bar(1350000,3500000,8500000,22000,'29405A')+dot(1150000,3250000,550000,ORANGE)+dot(3250000,3250000,550000,CYAN)+dot(5350000,3250000,550000,PINK)+dot(7450000,3250000,550000,GREEN)+dot(9550000,3250000,550000,YELLOW)+textbox('Baseline',900000,4200000,1200000,300000,14,WHITE,True,'c')+textbox('CPU / memory',2850000,4200000,1600000,300000,14,WHITE,True,'c')+textbox('HTTP 500s',4950000,4200000,1600000,300000,14,WHITE,True,'c')+textbox('Delete pod',7000000,4200000,1600000,300000,14,WHITE,True,'c')+textbox('Observe',9300000,4200000,1200000,300000,14,WHITE,True,'c')+textbox('Deploy → Monitor → Simulate → Detect → Recover',2250000,5250000,7500000,400000,20,CYAN,True,'c')))
    s.append(slide(header('Pressure is a signal, not a verdict','Experiment 01',10)+card('CPU load','GET /load?mode=cpu&seconds=20\n\nExpect: usage rises for the bounded work window.',850000,1900000,4300000,2700000,ORANGE,'Test',17)+card('Memory load','GET /load?mode=memory&mb=15\nrepeat up to six times\n\nExpect: working set rises in the receiving pod.',5550000,1900000,4300000,2700000,PINK,'Test',17)+textbox('Use the dashboard to compare behavior with configured limits. Do not invent measured percentages before running the cluster.',1300000,5300000,9000000,450000,18,MUTED,True,'c')))
    s.append(slide(header('Error rate becomes an alert','Experiment 02',11)+textbox('The application deliberately returns HTTP 500 responses so the alert path is visible.',850000,1800000,9500000,400000,19,WHITE,True)+card('Generate','1..20 → /load?mode=error',850000,2900000,3000000,1300000,PINK,'01',15)+card('Measure','demo_http_requests_total{status=~"5.."}',4100000,2900000,3000000,1300000,CYAN,'02',15)+card('Alert','ApplicationHighErrorRate\n> 10% for 1 minute',7350000,2900000,3000000,1300000,ORANGE,'03',15)+textbox('Alert evaluation is not notification delivery. Alertmanager receivers are a future extension.',1800000,5100000,8000000,350000,16,MUTED,True,'c')))
    s.append(slide(header('Self-healing belongs to Kubernetes','Experiment 03',12)+card('1  Delete','kubectl delete pod <name>',850000,2050000,2700000,1250000,PINK,'Action',16)+textbox('→',3650000,2400000,400000,300000,26,ORANGE,True,'c')+card('2  Reconcile','Deployment sees replicas below desired state.',4100000,2050000,2700000,1250000,ORANGE,'Controller',16)+textbox('→',6900000,2400000,400000,300000,26,ORANGE,True,'c')+card('3  Replace','A new pod starts and becomes ready.',7350000,2050000,2700000,1250000,GREEN,'Recovery',16)+textbox('Prometheus detects and displays the condition. Kubernetes performs the repair.',1600000,5100000,8500000,450000,19,CYAN,True,'c')))
    s.append(slide(header('Evidence checklist','Results',13)+textbox('The final report should use measured evidence from the local run.',850000,1800000,9000000,400000,20,WHITE,True)+card('Terminal','Pod status, replica count, replacement pod.',850000,2900000,3000000,1400000,CYAN,'Capture',16)+card('Prometheus','Target UP, query results, alert state.',4100000,2900000,3000000,1400000,ORANGE,'Capture',16)+card('Grafana','CPU, memory, request rate, 5xx graphs.',7350000,2900000,3000000,1400000,GREEN,'Capture',16)+textbox('Current deck status: design complete; live measurements pending Docker Desktop/Kubernetes startup.',1400000,5250000,9000000,400000,16,MUTED,True,'c')))
    s.append(slide(header('Boundaries and next steps','Scope',14)+card('Today','Local, single-node cluster\nSynthetic workload\nManual experiments',850000,2000000,3000000,1700000,ORANGE,'Limitations',17)+card('Next','Alertmanager receivers\nSLO / latency panels\nLoad testing',4100000,2000000,3000000,1700000,CYAN,'Future',17)+card('Scale','Multi-node monitoring\nPersistent storage\nCI/CD integration',7350000,2000000,3000000,1700000,GREEN,'Future',17)+textbox('A good mini-project is honest about what it measures and what it still needs to prove.',1500000,5200000,8500000,450000,19,WHITE,True,'c')))
    s.append(slide(header('The takeaway','Conclusion',15)+textbox('Reliability is a conversation between workload, signals, and control plane.',850000,1800000,9500000,550000,24,WHITE,True)+card('Prometheus','Collects and evaluates time series.',850000,3300000,3000000,1300000,ORANGE,'Observe',17)+card('Grafana','Makes behavior legible to people.',4100000,3300000,3000000,1300000,CYAN,'Explain',17)+card('Kubernetes','Reconciles desired workload state.',7350000,3300000,3000000,1300000,GREEN,'Recover',17)+textbox('Deploy  →  Monitor  →  Simulate  →  Detect  →  Recover',2200000,5350000,7500000,400000,20,ORANGE,True,'c')))
    s.append(slide(header('References','Appendix',16)+textbox('Kubernetes\nkubernetes.io/docs\n\nPrometheus\nprometheus.io/docs\n\nGrafana\ngrafana.com/docs',1100000,1900000,3300000,3400000,17,WHITE)+textbox('kube-prometheus-stack\ngithub.com/prometheus-community/helm-charts\n\nNode.js\nnodejs.org/docs\n\nDocker Desktop Kubernetes\ndocs.docker.com/desktop/use-desktop/kubernetes',6000000,1900000,4800000,3400000,17,WHITE)))
    s.append(slide(textbox('Questions?',850000,2100000,6000000,800000,38,WHITE,True)+textbox('Kubernetes Workload Reliability\nPrometheus  •  Grafana  •  Docker Desktop',880000,3350000,7000000,800000,20,MUTED)+textbox('Thank you',880000,5100000,4000000,450000,20,ORANGE,True)))
    return s


def rels(n):
    a = ['<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>', '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/printerSettings" Target="printerSettings/printerSettings1.bin"/>']
    a += [f'<Relationship Id="rId{i+2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide{i}.xml"/>' for i in range(1, n+1)]
    return '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'+''.join(a)+'</Relationships>'


def write(slides):
    ct = ['<Default Extension="xml" ContentType="application/xml"/>', '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>', '<Default Extension="bin" ContentType="application/vnd.openxmlformats-officedocument.presentationml.printerSettings"/>', '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>', '<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>', '<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>']
    ct += [f'<Override PartName="/ppt/slides/slide{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>' for i in range(1,len(slides)+1)]
    root = '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/></Relationships>'
    pres = '<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst><p:sldIdLst>'+''.join(f'<p:sldId id="{255+i}" r:id="rId{i+2}"/>' for i in range(1,len(slides)+1))+'</p:sldIdLst><p:sldSz cx="12192000" cy="6858000" type="screen16x9"/><p:notesSz cx="6858000" cy="9144000"/></p:presentation>'
    master = '<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld><p:sldLayoutIdLst><p:sldLayoutId id="1" r:id="rId1"/></p:sldLayoutIdLst><p:txStyles><p:titleStyle/><p:bodyStyle/><p:otherStyle/></p:txStyles></p:sldMaster>'
    layout = '<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank"><p:cSld name="Blank"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld></p:sldLayout>'
    with ZipFile(OUT, 'w', ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml','<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'+''.join(ct)+'</Types>')
        z.writestr('_rels/.rels',root); z.writestr('ppt/presentation.xml',pres); z.writestr('ppt/_rels/presentation.xml.rels',rels(len(slides)))
        z.writestr('ppt/slideMasters/slideMaster1.xml',master); z.writestr('ppt/slideMasters/_rels/slideMaster1.xml.rels','<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/></Relationships>')
        z.writestr('ppt/slideLayouts/slideLayout1.xml',layout); z.writestr('ppt/slideLayouts/_rels/slideLayout1.xml.rels','<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/></Relationships>')
        z.writestr('ppt/printerSettings/printerSettings1.bin',b'')
        for i,s in enumerate(slides,1):
            z.writestr(f'ppt/slides/slide{i}.xml',s); z.writestr(f'ppt/slides/_rels/slide{i}.xml.rels','<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/></Relationships>')


if __name__ == '__main__':
    deck = build(); write(deck); print(f'Generated {OUT} with {len(deck)} slides')

