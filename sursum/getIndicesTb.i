{util.i}
DEFINE VARIABLE cListaInd AS CHARACTER   NO-UNDO.
FOR EACH {1}._field 
    WHERE _field._field-name = '{2}',
    EACH {1}._index-field OF _field,
    EACH {1}._index OF _index-field :
    RUN incrvalor(INPUT-OUTPUT cListaInd,_index-name,",").
    
END.
RETURN cListaInd .
