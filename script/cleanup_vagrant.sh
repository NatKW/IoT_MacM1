#!/bin/bash

VAGRANT_PROJECT_DIR="/Users/thnab/Code/IoT_MACM1/p1"

cd "$VAGRANT_PROJECT_DIR" || exit

# Détruire les VM actives gérées par Vagrant
vagrant global-status --prune
ACTIVE_VMS=$(vagrant global-status | grep 'qemu' | awk '{print $1}')
if [ -n "$ACTIVE_VMS" ]; then
  for id in $ACTIVE_VMS; do
    vagrant destroy "$id" -f
    echo "y"
  done
else
  echo "Aucune VM active gérée par Vagrant n'a été trouvée."
fi

# Supprimer les fichiers de configuration Vagrant s'ils existent
if [ -d "$VAGRANT_PROJECT_DIR/.vagrant" ]; then
  rm -rf "$VAGRANT_PROJECT_DIR/.vagrant"
else
  echo "Aucun fichier de configuration Vagrant à supprimer."
fi

# Supprimer les VM QEMU
if command -v virsh &> /dev/null; then
  VMS=$(virsh list --all | awk 'NR>2 {print $2}')
  if [ -n "$VMS" ]; then
    for vm in $VMS; do
      virsh destroy "$vm"
      virsh undefine "$vm"
    done
  else
    echo "Aucune VM QEMU à supprimer."
  fi
fi

# Nettoyer les fichiers temporaires
if compgen -G "/tmp/vagrant*" > /dev/null; then
  rm -rf /tmp/vagrant*
else
  echo "Aucun fichier temporaire Vagrant à supprimer."
fi

# Lister les ports à vérifier:
PORTS=(50022 50024 50025)

# pour chacun des ports:
for PORT in "${PORTS[@]}"; do
  # Trouver le PID de chq process qui rattaché au port ouvert :
  PID=$(lsof -ti :$PORT)

  # Trouver si un PID matchvagrant ssh pour un port : 
  if [ -n "$PID" ]; then
    echo "Found process listening on port $PORT with PID: $PID"
    
    # Kill les process
    kill -9 $PID
    echo "Process $PID on port $PORT killed."
    
    # Vérifier si les process ont bien été stoppés:
    if ! ps -p $PID > /dev/null; then
      echo "Process $PID on port $PORT successfully terminated."
    else
      echo "Failed to terminate process $PID on port $PORT."
    fi
  else
    echo "No process found listening on port $PORT."
  fi
done
