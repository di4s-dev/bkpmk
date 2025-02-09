> [!CAUTION]
> ESSE PROJETO É FORNECIDO "COMO ESTÁ", E NENHUMA GARANTIA, EXPRESSA OU IMPLÍCITA, É DADA. AVALIE O CÓDIGO E UTILIZE POR SUA CONTA E RISCO. 

# bkpmk - Backup Mikrotik ( routeros v6 )

Shell script para fazer backup de roteadores Mikrotik.

O backup é realizado através de SSH com autenticação por chave.

É recomendado criar um usuário específico para executar o backup no servidor e nos roteadores.

O usuário no roteador precisa ter as seguintes permissões: ssh, ftp, read, write, policy e sensitive

### Instalação

Para instalar siga os seguintes passos:

```
# Instale as dependencias 
apt-get install git jq sqlite3 


# Crie o usuário que será responsável pelo backup
adduser backup_mikrotik

su - backup_mikrotik 


# Faça o download do código
git clone https://github.com/di4s-dev/bkpmk .bkpmk


# Crie o banco de dados 
cat .bkpmk/db.sql | sqlite3 .bkpmk/database.db


# Crie o storage para armazenar os backups
mkdir storage 


# Crie as chaves SSH - Obs.: Não coloque senha na chave
ssh-keygen -t rsa -f ~/.ssh/bkpmk


# Crie o arquivo de configuração
nano .bkpmk/config/settings.json 

# Preencha com o seguinte conteudo

{
    "DB": "/home/backup_mikrotik/.bkpmk/database.db",
    "storage": "/home/backup_mikrotik/storage",
    "privateKey": "/home/backup_mikrotik/.ssh/bkpmk",
    "publicKey": "/home/backup_mikrotik/.ssh/bkpmk.pub",
    "keep": 7
}


# Configure a PATH
echo 'PATH=$HOME/.bkpmk/:$PATH' >> ~/.profile

source ~/.profile 


# Faça o agendamento
crontab -e 

# Adicione a linha
00 23 * * * /home/backup_mikrotik/.bkpmk/bkpmk backup

```

### Gerenciar roteadores

Para gerenciar os roteadores use:

```
# Para adicionar
# bkpmk device add usuario ip portaSSH
bkpmk device add backup 192.168.0.1 22

# Para ver a lista de roteadores
bkpmk device list

# Para remover
# bkpmk device remove ip
bkpmk device remove 192.168.0.1

```
