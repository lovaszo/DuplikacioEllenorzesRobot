import os
from robot.api.deco import keyword

@keyword('Find Docx Files Recursively')
def find_docx_files_recursively(directory):
    docx_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith('.docx') and not file.startswith('~$'):
                docx_files.append(os.path.abspath(os.path.join(root, file)))
    return docx_files
