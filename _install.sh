#!/bin/bash

# _install.sh - Script para instalar e executar o LuaX, destravando completamente o sistema
# Autor: @0xffff00 (Instagram)

# Verifica se o script está sendo executado com privilégios de root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root. Use sudo ./_install.sh"
  exit 1
fi

echo "Iniciando instalação do LuaX por @0xffff00..."

# 1. Limpar execuções passadas do luax
echo "Limpando versões anteriores do LuaX..."
if [ -f "/usr/local/bin/luax" ]; then
  rm -f /usr/local/bin/luax
  echo "Versão antiga em /usr/local/bin/luax removida."
fi
if [ -f "./luax.sh" ]; then
  rm -f ./luax.sh
  echo "Versão antiga em ./luax.sh removida."
fi

# 2. Criar o script luax.sh
echo "Criando nova versão do script luax.sh..."
cat > luax.sh << 'EOF'
#!/bin/bash

# LuaX - Script de configuração do sistema Ubuntu, abandonando sudo
# Autor: @0xffff00 (Instagram)

# Verifica argumentos para desinstalação
if [ "$1" = "-u" ]; then
  echo "Iniciando desinstalação do LuaX..."

  # Restaurar sudo e desabilitar conta root
  echo "Restaurando configurações do sudo e desabilitando conta root..."
  passwd -l root
  if [ $? -eq 0 ]; then
    echo "Conta root desabilitada."
cp "$BASHRC_FILE" "$BASHRC_FILE.bak"
echo "Backup do .bashrc criado em $BASHRC_FILE.bak"

  else
    echo "Erro ao desabilitar conta root. Verifique manualmente."
    exit 1
  fi

  # Restaurar permissões originais
  USER_HOME="/home/$SUDO_USER"
  echo "Restaurando permissões padrão para $SUDO_USER..."
  chown -R root:root /usr/local/bin /usr/local/lib /etc/apt
  chmod -R 755 /usr/local/bin /usr/local/lib /etc/apt
  PYTHON_LIB_DIR="/usr/local/lib/python3.$(python3 -c 'import sys; print(sys.version_info.minor)')"
  chmod -R 755 "$PYTHON_LIB_DIR"
  gpasswd -d "$SUDO_USER" root
  echo "Permissões restauradas."

  # Restaurar .bashrc
  if [ -f "$USER_HOME/.bashrc.bak" ]; then
    mv "$USER_HOME/.bashrc.bak" "$USER_HOME/.bashrc"
    echo "Arquivo .bashrc restaurado a partir do backup."
  fi

  # Remover configurações do apt
  APT_CONF="/etc/apt/apt.conf.d/99luax"
  if [ -f "$APT_CONF" ]; then
    rm -f "$APT_CONF"
    echo "Configurações do apt restauradas."
  fi

  # Remover configurações do pip
  PIP_CONF="/etc/pip.conf"
  if [ -f "$PIP_CONF" ]; then
    rm -f "$PIP_CONF"
    echo "Configurações do pip restauradas."
  fi

  # Reativar AppArmor
  if [ -f "/etc/apparmor.d/tunables" ]; then
    systemctl enable apparmor
    systemctl start apparmor
    echo "AppArmor reativado."
  else
    echo "AppArmor não encontrado. Pulando reativação."
  fi

  # Reativar UFW
  if command -v ufw >/dev/null; then
    ufw enable
    echo "UFW (firewall) reativado."
  else
    echo "UFW não encontrado. Pulando reativação."
  fi

  # Remover script LuaX
  if [ -f "/usr/local/bin/luax" ]; then
    rm -f "/usr/local/bin/luax"
    echo "Script LuaX removido de /usr/local/bin/luax."
  fi

  # Remover aliases
  sed -i '/# Aliases do LuaX para comandos sem sudo/d' "$USER_HOME/.bashrc"
  sed -i '/alias apt=/d' "$USER_HOME/.bashrc"
  sed -i '/alias npm=/d' "$USER_HOME/.bashrc"
  sed -i '/alias pip3=/d' "$USER_HOME/.bashrc"
  echo "Aliases removidos do .bashrc."

  echo "Desinstalação concluída. Sistema restaurado."
  echo "Execute 'source ~/.bashrc' ou reinicie o terminal para aplicar as mudanças."
  exit 0
fi

# Executar automaticamente como root, sem necessidade de sudo
if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

# Nome do script
SCRIPT_NAME="LuaX"
echo "Iniciando configuração do $SCRIPT_NAME..."

# 1. Habilitar conta root e abandonar sudo
echo "Habilitando conta root e configurando ambiente..."
# Definir senha para a conta root (usando senha 'luax')
echo "root:luax" | chpasswd
if [ $? -eq 0 ]; then
  echo "Conta root habilitada com senha 'luax'. Use 'su -' para logar como root."
else
  echo "Erro ao habilitar conta root. Verifique manualmente."
  exit 1
fi

# Ajustar permissões para o usuário atual executar comandos administrativos sem sudo
USER_HOME="/home/$SUDO_USER"
echo "Configurando permissões amplas para $SUDO_USER..."
chown -R "$SUDO_USER:$SUDO_USER" /usr/local/bin /usr/local/lib /etc/apt
chmod -R 777 /usr/local/bin /usr/local/lib /etc/apt
usermod -aG root "$SUDO_USER"
echo "Permissões ajustadas para permitir comandos sem sudo."

# 2. Personalizar o prompt do terminal (vermelho, formato root@root:~$)
echo "Configurando tema vermelho para o terminal..."
BASHRC_FILE="$USER_HOME/.bashrc"
if [ ! -f "$BASHRC_FILE" ]; then
  echo "Arquivo .bashrc não encontrado. Criando novo..."
  touch "$BASHRC_FILE"
  chown "$SUDO_USER:$SUDO_USER" "$BASHRC_FILE"
fi

# Backup do .bashrc
cp "$BASHRC_FILE" "$BASHRC_FILE.bak"
echo "Backup do .bashrc criado em $BASHRC_FILE.bak"

# Adicionar configuração do prompt
cat >> "$BASHRC_FILE" << 'EOL'
# Configuração do LuaX - Prompt vermelho
PS1='\[\e[31m\]root@root:\w\$\[\e[m\] '
EOL

# Aplicar permissões ao .bashrc
chown "$SUDO_USER:$SUDO_USER" "$BASHRC_FILE"
chmod 644 "$BASHRC_FILE"
echo "Prompt do terminal configurado com tema vermelho."

# 3. Desbloquear restrições do sistema
echo "Aplicando configurações de desbloqueio do sistema..."

# 3.1. Desativar AppArmor
if systemctl is-active apparmor >/dev/null; then
  systemctl stop apparmor
  systemctl disable apparmor
  echo "AppArmor desativado."
else
  echo "AppArmor já está desativado ou não está presente."
fi

# 3.2. Desativar UFW (firewall)
if ufw status | grep -q "Status: active"; then
  ufw disable
  echo "UFW (firewall) desativado."
else
  echo "UFW já está desativado ou não está presente."
fi

# 3.3. Configurar apt para permitir instalações sem restrições
echo "Configurando apt para instalações sem restrições..."
APT_CONF="/etc/apt/apt.conf.d/99luax"
cat > "$APT_CONF" << 'EOL'
APT::Get::AllowUnauthenticated "true";
Acquire::AllowInsecureRepositories "true";
EOL
chmod 644 "$APT_CONF"
echo "Configurações do apt ajustadas para permitir qualquer origem."

# 3.4. Configurar Python e pip para instalações globais
echo "Configurando Python/pip para instalações globais..."
# Garantir que pip está instalado
if ! command -v pip3 >/dev/null; then
  apt-get update
  apt-get install -y python3-pip
fi

# Ajustar permissões do diretório de bibliotecas Python
PYTHON_LIB_DIR="/usr/local/lib/python3.$(python3 -c 'import sys; print(sys.version_info.minor)')"
chmod -R 777 "$PYTHON_LIB_DIR"
echo "Permissões ajustadas para $PYTHON_LIB_DIR."

# Ajustar permissões do diretório de binários
chmod -R 777 /usr/local/bin
echo "Permissões ajustadas para /usr/local/bin."

# Criar configuração do pip para ignorar avisos de venv
PIP_CONF="/etc/pip.conf"
if [ ! -f "$PIP_CONF" ]; then
  mkdir -p /etc
  cat > "$PIP_CONF" << 'EOL'
[global]
break-system-packages = true
EOL
  echo "Configuração do pip ajustada para instalações globais."
else
  echo "Arquivo pip.conf já existe. Verifique manualmente para evitar conflitos."
fi

# 4. Tornar o script executável e permanente
echo "Tornando o $SCRIPT_NAME permanente..."
SCRIPT_DEST="/usr/local/bin/luax"
cp "$0" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"
echo "Script $SCRIPT_NAME instalado em $SCRIPT_DEST."

# 5. Mensagem final
echo "Configuração do $SCRIPT_NAME concluída!"
echo "Execute 'source ~/.bashrc' ou reinicie o terminal para aplicar o novo prompt."
echo "AVISO: O sistema agora permite comandos sem sudo e tem permissões amplas."
echo "Use com extremo cuidado, pois o sistema está vulnerável a erros e malware!"
echo "Créditos: @0xffff00 (Instagram)"

exit 0
EOF

# 3. Tornar luax.sh executável
chmod +x luax.sh
echo "Script luax.sh criado e tornado executável."

# 4. Instalar dependências necessárias
echo "Instalando dependências necessárias..."
apt-get update
apt-get install -y python3-pip npm

# 5. Executar luax.sh
echo "Executando luax.sh..."
./luax.sh
if [ $? -ne 0 ]; then
  echo "Erro ao executar luax.sh. Verifique manualmente."
  exit 1
fi

# 6. Testar instalação do selenium
echo "Testando instalação do selenium..."
pip3 install selenium
if [ $? -eq 0 ]; then
  echo "Selenium instalado com sucesso!"
else
  echo "Erro ao instalar selenium. Verifique permissões ou conectividade."
  exit 1
fi

# 7. Configurar aliases para comandos sem sudo
echo "Configurando aliases para comandos sem sudo..."
cat >> "$USER_HOME/.bashrc" << 'EOL'
# Aliases do LuaX para comandos sem sudo
alias apt='apt-get'
alias npm='npm'
alias pip3='pip3'
EOL
echo "Aliases configurados para apt, npm e pip3."

# 8. Exibir mensagem de sucesso em verde
echo -e "\033[32m[0xffff00]: Sucesso. Instalado com sucesso!\033[0m"

exit 0
