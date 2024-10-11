#!/bin/bash

# Parcourir tous les dossiers du répertoire IoT : 
#for VAGRANT_PROJECT_DIR in /Users/thnab/Code/IoT/p*/; do

# Ou ne parcourir qu'un seul dossier du répertoire IoT :
VAGRANT_PROJECT_DIR="/Users/thnab/Code/IoT/p1"

# Vérifier si le répertoire existe
if [ ! -d "$VAGRANT_PROJECT_DIR" ]; then
  echo "Le répertoire $VAGRANT_PROJECT_DIR n'existe pas."
  exit 1
fi
#done              # --> A rajouter pour la boucle 'for'

# Se déplacer vers le répertoire du projet
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

# Supprimer les réseaux QEMU/KVM
if command -v virsh &> /dev/null; then
  NETWORKS=$(virsh net-list --all | awk 'NR>2 {print $1}')
  if [ -n "$NETWORKS" ]; then
    for net in $NETWORKS; do
      virsh net-destroy "$net"
      virsh net-undefine "$net"
    done
  else
    echo "Aucun réseau QEMU/KVM à supprimer."
  fi
fi

# Supprimer les VM QEMU/KVM
if command -v virsh &> /dev/null; then
  VMS=$(virsh list --all | awk 'NR>2 {print $2}')
  if [ -n "$VMS" ]; then
    for vm in $VMS; do
      virsh destroy "$vm"
      virsh undefine "$vm"
    done
  else
    echo "Aucune VM QEMU/KVM à supprimer."
  fi
fi

# Nettoyer les fichiers temporaires
if compgen -G "/tmp/vagrant*" > /dev/null; then
  rm -rf /tmp/vagrant*
else
  echo "Aucun fichier temporaire Vagrant à supprimer."
fi

# List of ports to check
PORTS=(50022 50024 50025)

# Loop through each port
for PORT in "${PORTS[@]}"; do
  # Find the PID of the process listening on the specified port
  PID=$(lsof -ti :$PORT)

  # Check if a PID was found for the port
  if [ -n "$PID" ]; then
    echo "Found process listening on port $PORT with PID: $PID"
    
    # Kill the process
    kill -9 $PID
    echo "Process $PID on port $PORT killed."
    
    # Check if the process was successfully killed
    if ! ps -p $PID > /dev/null; then
      echo "Process $PID on port $PORT successfully terminated."
    else
      echo "Failed to terminate process $PID on port $PORT."
    fi
  else
    echo "No process found listening on port $PORT."
  fi
done
