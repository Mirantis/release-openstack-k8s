import time

# The master toctree document.
master_doc = 'index'

# The suffix of source filenames.
source_suffix = '.rst'

extensions = [
  'reno.sphinxext',
]

# General information about the project.
project = u'OpenStack on Kubernetes Release Notes'
copyright = u'2019-{} Mirantis, Inc.'.format(time.strftime("%Y"))

latex_documents = [
    (
        'index',
        '%s.tex' % project,
        u'%s Release Notes Documentation' % project,
        u'Mirantis',
        'manual'
    ),
]
