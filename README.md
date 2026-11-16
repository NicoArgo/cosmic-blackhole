# cosmic-blackhole — POP Flow

Um buraco negro na área de trabalho. Arquivo solto que cai nela (download,
captura de tela, algo salvo ali) vai sozinho para uma pasta, por padrão
**CAOS**, que ganha o ícone de buraco negro. As pastas e os atalhos que você
põe na área de trabalho ficam onde estão.

**Opcional.** O `install-all.sh` da suíte pergunta antes, e a resposta padrão é
não. Tudo fica na sua conta, sem `sudo`.

## Uso

```bash
./install.sh                    # pasta "CAOS" na área de trabalho
./install.sh --folder Bagunça   # outro nome (ou um caminho absoluto)
./install.sh --no-icon          # sem trocar o ícone da pasta
./uninstall.sh                  # desfaz; a pasta e os arquivos ficam
```

Rodar o `install.sh` de novo troca a pasta. O que já foi movido continua
na pasta antiga.

## O que vai e o que fica

| Vai para a pasta | Fica na área de trabalho |
|---|---|
| arquivos comuns | pastas |
| | links (atalhos) e lançadores `.desktop` |
| | arquivos ocultos (`.algo`) e de backup (`algo~`) |
| | download em andamento (`.part`, `.crdownload`, `.tmp`…) |

- **Arquivo ainda sendo gravado:** um arquivo alterado há menos de 3 s espera
  a próxima rodada, para não mover um download pela metade.
- **Mesmo nome:** se já existe um arquivo com o nome na pasta, o novo vira
  `nome (1).ext`, `nome (2).ext`… Nada é sobrescrito.

## Como funciona

- **Gatilho:** o `pop-flow-blackhole.path` (systemd do usuário) roda a limpeza
  a cada mudança na área de trabalho. O `.timer` repete a cada 2 min, como
  rede de segurança.
- **Ícone:** fica no atributo `metadata::custom-icon` da pasta, que o
  cosmic-files do POP Flow mostra (o Nautilus também). O cosmic-files de
  fábrica ignora esse atributo.

## Arquivos

| No repo | Instalado em |
|---|---|
| `bin/pop-flow-blackhole` | `~/.local/bin/pop-flow-blackhole` |
| `systemd/pop-flow-blackhole.{service,path,timer}` | `~/.config/systemd/user/` (com o caminho da área de trabalho e da pasta) |
| `data/blackhole.svg` | `~/.local/share/icons/pop-flow/blackhole.svg` |

Uma versão feita à mão antes deste componente (`caos-blackhole`) é
desligada e substituída pelo `install.sh`.
