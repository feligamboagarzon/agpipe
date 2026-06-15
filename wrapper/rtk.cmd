@echo off
REM agpipe shim para `rtk` (Windows nativo). install.ps1 reemplaza los placeholders.
REM Debe ir PRIMERO en el PATH (delante del rtk real); delega en rtkread.py.
set "AGPIPE_VENV=__AGPIPE_VENV__"
set "AGPIPE_REAL_RTK=__AGPIPE_REAL_RTK__"
"%AGPIPE_VENV%\Scripts\python.exe" "__AGPIPE_HOME__\wrapper\rtkread.py" %*
