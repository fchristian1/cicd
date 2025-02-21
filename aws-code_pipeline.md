## Hauptkomponenten von AWS CodePipeline:

- Pipeline: 

    Eine Pipeline definiert den Workflow für die Softwarefreigabe und besteht aus mehreren aufeinanderfolgenden Stufen.

---
- Stufen (Stages):  

    Jede Stufe repräsentiert einen logischen Abschnitt des Workflows, wie z.B. Quellcode-Abruf, Build-Prozess oder Deployment.
---
- Aktionen (Actions):

    Innerhalb jeder Stufe werden spezifische Aktionen ausgeführt, wie z.B. Code aus einem Repository abrufen, Tests durchführen oder Anwendungen bereitstellen.


## Eigenschaften von AWS CodePipeline:

- Automatisierung des Release-Prozesses:

    Jede Codeänderung durchläuft automatisch den definierten Workflow, was zu schnelleren und effizienteren Releases führt.
---
- Integration mit anderen AWS-Services und Drittanbieter-Tools:

    CodePipeline lässt sich nahtlos mit Services wie AWS CodeBuild, AWS CodeDeploy sowie mit Tools wie GitHub, Jenkins und anderen integrieren.
---
- Skalierbarkeit und Zuverlässigkeit: 

    Als vollständig verwalteter Service skaliert CodePipeline automatisch entsprechend den Anforderungen und bietet eine hohe Verfügbarkeit.
---
- Integration von AWS CodePipeline mit IAM:

    Mit IAM können Sie den Zugriff auf CodePipeline-Ressourcen durch das Erstellen und Verwalten von Richtlinien präzise steuern.
