#/bin/bash
cd ansible &&
    bash ./prep.sh &&
    ansible-playbook -i inventory ping_wait.yml &&
    ansible-playbook -i inventory playbook.yml
