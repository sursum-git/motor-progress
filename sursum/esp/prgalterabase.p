DEF VAR c-dbase AS CHARACTER NO-UNDO. /* Descricao da base */

ASSIGN c-dbase = "(BASE TESTE)".

FIND FIRST usuar_mestre SHARE-LOCK WHERE
           usuar_mestre.cod_usuario = "super".

ASSIGN usuar_mestre.cod_senha            = BASE64-ENCODE(SHA1-DIGEST("teste"))
       usuar_mestre.cod_senha_framework  = BASE64-ENCODE(SHA1-DIGEST("teste"))
       usuar_mestre.dat_inic_valid       = 01/01/2001
       usuar_mestre.dat_fim_valid        = 12/31/9999
       usuar_mestre.dat_valid_senha      = 12/31/9999
       usuar_mestre.num_dias_valid_senha = 999.

FOR EACH fnd_empres SHARE-LOCK:
    ASSIGN fnd_empres.des_razao_social = c-dbase + " " + TRIM(fnd_empres.des_razao_social) + " [" + STRING(TODAY,"99/99/99") + " as " + STRING(TIME,"hh:mm") + "]".

    ASSIGN fnd_empres.cod_broker = REPLACE(fnd_empres.cod_broker,"prd","tst").
    ASSIGN fnd_empres.cod_broker = REPLACE(fnd_empres.cod_broker,"bkp","bkt").
END.

FOR EACH bco_empres SHARE-LOCK
      BY bco_empres.cod_empresa
	  BY bco_empres.cod_param_conex:

    ASSIGN bco_empres.cod_param_conex = REPLACE(bco_empres.cod_param_conex,"-S 10","-S 20")
           bco_empres.cod_param_conex = REPLACE(bco_empres.cod_param_conex,"-S 30","-S 40").
		 
    ASSIGN bco_empres.cod_param_conex = REPLACE(bco_empres.cod_param_conex,"192.168.0.44","192.168.0.39").
END.


