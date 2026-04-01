set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

publish:
    pesde install
    wally install
    pesde publish
    wally publish


test:
    rojo serve test.project.json