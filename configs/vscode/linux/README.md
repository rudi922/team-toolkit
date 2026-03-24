# Einstellungen für VSCode unter Linux

## Erweiterungen VSIX

**Erweiterungen (Auflistung) in Datei speichern**  

``` bash
code --list-extensions --show-versions > extensions_list.txt
```

**Erweiterungen (Auflistung) auf anderem PC aus Auflistung installieren**  

``` bash
while read extension; do
    code --install-extension "$extension"
done < extensions_list.txt
```

