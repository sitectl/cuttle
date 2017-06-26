# {{ ansible_managed }}

import os
import glob

transcripts = glob.glob('{{ ttyspy.server.transcript_glob }}')

for transcript in transcripts:
    if ".xz" not in transcript:
        os.system('xz ' + transcript)
