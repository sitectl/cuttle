# {{ ansible_managed }}
import sys
sys.path.append('{{ graphite.path.virtualenv }}/webapp')

from graphite.wsgi import application
