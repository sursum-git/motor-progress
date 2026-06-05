DEFINE VARIABLE h       AS HANDLE      NO-UNDO.
DEFINE VARIABLE cErro   AS CHARACTER   NO-UNDO.
RUN esbo/bocerthttps.p PERSIST SET h .
RUN setDirCertificados IN h('t:\certs').


/*RUN setNomeCertificado IN h('4042bcee.0').
RUN setListaCertificados IN h('404bd867.0,8d33f237.0').
RUN exec IN h .
RUN getErro IN h(OUTPUT cErro).
*/



RUN setListaCertificados IN h('404bd867.0,8d33f237.0').
RUN exec IN h .
RUN getErro IN h(OUTPUT cErro).
MESSAGE cErro
    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
