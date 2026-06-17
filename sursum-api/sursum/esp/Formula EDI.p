/*FOR EACH formul_edi:
    DISP formul_edi.cdn_formul_edi.*/
    FOR EACH ems5.compon_formul
       WHERE substr(des_contdo_compon_edi,1,5) = '71539' .
        DISP des_contdo_compon_edi WITH 1 COL WIDTH 550.
    END.
   /* FOR EACH trad_element_edi OF formul_edi:
        DISP trad_element_edi WITH 1 COL WIDTH 550.
    END.*/
/*END.*/
/*formul_edi:
  compon_formul_edi OF formul_edi (cdn_formul_edi)
  trad_element_edi OF formul_edi (cdn_formul_edi)
  formul_edi OF element_edi (cdn_element_edi)
  formul_edi OF format_dat_element_edi (cdn_element_edi)
  formul_edi OF format_dec_element_edi (cdn_element_edi)
  formul_edi OF format_int_element_edi (cdn_element_edi)
  formul_edi OF mapa_edi (cdn_trans_edi,cdn_mapa_edi)
  formul_edi OF mapa_segment_edi (cdn_trans_edi,cdn_mapa_edi,cdn_segment_edi)
  formul_edi OF mapa_segment_element_edi (cdn_trans_edi,cdn_mapa_edi,cdn_segm
  formul_edi OF param_darf_ap (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_acr (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_apb (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_apl (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_bgc (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_cfl (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_cmg (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_eec (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_ems (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_gld (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_pat (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF param_geral_sco (dat_ult_atualiz,hra_ult_atualiz)
  formul_edi OF segment_edi (cdn_segment_edi)
  formul_edi OF segment_element_edi (cdn_segment_edi,cdn_element_edi)
  formul_edi OF trans_edi (cdn_trans_edi)
  formul_edi OF trans_segment_edi (cdn_trans_edi,cdn_segment_edi)


*/
