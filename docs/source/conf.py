# -*- coding: utf-8 -*-
#
# Seqan3 documentation build configuration file, created by
# sphinx-quickstart on Wed Feb 14 11:57:40 2018.
#
# This file is execfile()d with the current directory set to its
# containing dir.
#
# Note that not all possible configuration values are present in this
# autogenerated file.
#
# All configuration values have a default; values that are commented out
# serve to show the default.

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))
import os, subprocess, sys

def run_doxygen(folder, includeDir=None):
    """Run the doxygen make command in the designated folder"""
    try:
        retcode = subprocess.call("cd %s; cmake -DSEQAN3_INCLUDE_DIR=%s ." % (folder, includeDir), shell=True)
        if retcode < 0:
            sys.stderr.write("cmake for doxygen failed")

        retcode = subprocess.call("cd %s; make doc_devel" % folder, shell=True)
        if retcode < 0:
            sys.stderr.write("doxygen terminated by signal %s" % (-retcode))
    except OSError as e:
        sys.stderr.write("doxygen execution failed: %s" % e)


def generate_rtd(app):
    """Run the doxygen make commands if we're on the ReadTheDocs server"""

    read_the_docs_build = os.environ.get('READTHEDOCS', None) == 'True'

    if read_the_docs_build:

        cloneDir = "../../seqan3"
        doxygenDir = "../../doxygen"
        includeDir = "../../seqan3/include/seqan3/"
        sourceDir = "../source/"

    else:

        cloneDir = "../seqan3"
        doxygenDir = "../doxygen"
        includeDir = "../seqan3/include/seqan3/"
        sourceDir = "./source/"

    download_seqan(cloneDir)
    run_doxygen(doxygenDir, includeDir)
    generate_source(includeDir, sourceDir)


def download_seqan(folder):
    """Download SeqAn repository to designated folder"""

    try:
        retcode = subprocess.call("git clone -b fix_docs https://github.com/eseiler/seqan3.git %s" % folder, shell=True)
        if retcode < 0:
            sys.stderr.write("git clone terminated by signal %s" % (-retcode))
    except OSError as e:
        sys.stderr.write("download SeqAn execution failed: %s" % e)
    
def generate_source(inDir, outDir):
    generateIndex(inDir, outDir)
    generateRSTs(inDir, outDir, True)

def setup(app):

    # Add hook
    app.connect("builder-inited", generate_rtd)

#  written by Jongkyu Kim (j.kim@fu-berlin.de)

CAT_NAME = "Modules"
INDEX_TEMP = "_index.rst"

def generateIndex(inDir, outDir):
    listModules = []
    for fileName in os.listdir(inDir) :
        if os.path.isdir(inDir + fileName) == True:
            listModules.append(fileName)  
    listModules = sorted(listModules)

    # generate index.rst
    inFile = open(outDir + INDEX_TEMP, "r")
    outFile = open(outDir + "index.rst", "w")
    for line in inFile :
        outFile.write(line)
    inFile.close()
    outFile.write("   :caption: %s:\n\n" % CAT_NAME)
    for moduleName in listModules :
        outFile.write("   %s\n" % (moduleName))
    outFile.close()

def generateRST(outDir, moduleName, listModules, listFiles) :
    if len(listModules) > 0 and os.path.isdir(outDir) == False:
        os.mkdir(outDir)

    # title
    outFile = open(outDir + ".rst","w")
    outFile.write(moduleName[0].upper() + moduleName[1:] + "\n")
    outFile.write("=" * len(moduleName) + "\n\n")

    # doxygenfile
    for fileName in listFiles :
        outFile.write(".. doxygenfile:: %s\n" % (outDir, fileName))
        outFile.write("   :project: Seqan3\n\n") # TODO generic

    # toctree
    outFile.write(".. toctree::\n")
    outFile.write("   :caption: %s:\n" % CAT_NAME)
    outFile.write("   :titlesonly:\n")
    outFile.write("   :maxdepth: 1\n")
    outFile.write("   :hidden:\n\n")
    for childModuleName in listModules :
       outFile.write("   %s/%s\n" % (moduleName, childModuleName) )
    outFile.close()

def generateRSTs(inDir, outDir, isRoot=False):
    listModules = []
    listFiles = []
    for fileName in os.listdir(inDir) :
        if os.path.isdir(inDir + fileName) == True:
            listModules.append(fileName)  
        else :
            fileExt = fileName.split(".")[-1]
            if fileExt == "hpp" or fileExt == "cpp" :
                listFiles.append(fileName)
    
    listModules = sorted(listModules)
    listFiles = sorted(listFiles)

    print isRoot, inDir, outDir, listModules, listFiles

    if isRoot == False :
        moduleName = outDir.split("/")[-1]
        generateRST(outDir, moduleName, listModules, listFiles)


    for moduleName in listModules :
        curInDir = inDir + moduleName
        curOutDir = outDir + moduleName
        generateRSTs(curInDir, curOutDir, False)

# -- General configuration ------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#
# needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = ['breathe']
breathe_projects = { "Seqan3": "../../doxygen/devel_doc/xml/" }
breathe_default_project = "Seqan3"

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
#
# source_suffix = ['.rst', '.md']
source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# General information about the project.
project = u'Seqan3'
copyright = u'2018, Seqan Developers'
author = u'Seqan Developers'

# The version info for the project you're documenting, acts as replacement for
# |version| and |release|, also used in various other places throughout the
# built documents.
#
# The short X.Y version.
version = u'0.0.1'
# The full version, including alpha/beta/rc tags.
release = u'0.0.1'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#
# This is also used if you do content translation via gettext catalogs.
# Usually you set "language" from the command line for these cases.
language = None

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This patterns also effect to html_static_path and html_extra_path
exclude_patterns = []

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# If true, `todo` and `todoList` produce output, else they produce nothing.
todo_include_todos = False


# -- Options for HTML output ----------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#
# html_theme_options = {}

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

# Custom sidebar templates, must be a dictionary that maps document names
# to template names.
#
# This is required for the alabaster theme
# refs: http://alabaster.readthedocs.io/en/latest/installation.html#sidebars
html_sidebars = {
    '**': [
        'relations.html',  # needs 'show_related': True theme option to display
        'searchbox.html',
    ]
}


# -- Options for HTMLHelp output ------------------------------------------

# Output file base name for HTML help builder.
htmlhelp_basename = 'Seqan3doc'


# -- Options for LaTeX output ---------------------------------------------

latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
    #
    # 'papersize': 'letterpaper',

    # The font size ('10pt', '11pt' or '12pt').
    #
    # 'pointsize': '10pt',

    # Additional stuff for the LaTeX preamble.
    #
    # 'preamble': '',

    # Latex figure (float) alignment
    #
    # 'figure_align': 'htbp',
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
    (master_doc, 'Seqan3.tex', u'Seqan3 Documentation',
     u'Enrico Seiler', 'manual'),
]


# -- Options for manual page output ---------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    (master_doc, 'seqan3', u'Seqan3 Documentation',
     [author], 1)
]


# -- Options for Texinfo output -------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (master_doc, 'Seqan3', u'Seqan3 Documentation',
     author, 'Seqan3', 'One line description of project.',
     'Miscellaneous'),
]
