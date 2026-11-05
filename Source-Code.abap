REPORT ZMA_A.


*---------------------------------------------------------------------*
* Define Structure for Sales Order Header (VBAK)
*---------------------------------------------------------------------*

TYPES:BEGIN OF str_vbak ,
        vbeln TYPE vbeln_va,  "Sales Document Number
        erdat TYPE erdat,     "Created Date
        erzet TYPE erzet,     "Created Time
        ernam TYPE ernam,     "Created By User
        vbtyp TYPE vbtypl,    "Sales Document Category
      END OF str_VBAK .

*---------------------------------------------------------------------*
* Define Structure for Sales Order Items (VBAP)
*---------------------------------------------------------------------*

TYPES: BEGIN OF STR_vbap,
         vbeln TYPE vbeln_va, "Sales Document Number
         posnr TYPE posnr,    "Sales Document Item
         matnr TYPE matnr,    "Material Number
       END   OF STR_vbap.

*---------------------------------------------------------------------*
* Declare Internal Tables and Work Areas
*---------------------------------------------------------------------*

DATA : it_vbak TYPE TABLE OF str_VBAK,
       wa_vbak TYPE str_vbak.

DATA : it_vbap TYPE TABLE OF str_VBAP,
       wa_vbap TYPE str_vbap.

*---------------------------------------------------------------------*
* ALV Field Catalog Declaration
*---------------------------------------------------------------------*

DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
      wa_fieldcat TYPE slis_fieldcat_alv.

*---------------------------------------------------------------------*
* ALV Sorting Declaration
*---------------------------------------------------------------------*

DATA: it_sort TYPE slis_t_sortinfo_alv,
      wa_sort TYPE slis_sortinfo_alv.

*---------------------------------------------------------------------*
* Final Output Internal Table
*---------------------------------------------------------------------*

DATA: it_final TYPE TABLE OF zma_alv_str,
      wa_final TYPE zma_alv_str .

*---------------------------------------------------------------------*
* ALV Filter Declaration
*---------------------------------------------------------------------*

DATA: it_filter TYPE slis_t_filter_alv,
      wa_filter TYPE slis_filter_alv.

*---------------------------------------------------------------------*
* ALV Header Declaration
*---------------------------------------------------------------------*

DATA: it_list TYPE slis_t_listheader,
      wa_list TYPE slis_listheader.

*---------------------------------------------------------------------*
* Variables for Header Information
*---------------------------------------------------------------------*

DATA: lv_input TYPE string,
      lv_lines TYPE c LENGTH 5.
*---------------------------------------------------------------------*
* Selection Screen
*---------------------------------------------------------------------*

DATA:lv_vblen TYPE vbeln_va.

SELECT-OPTIONS : s_vbeln FOR lv_vblen.

*---------------------------------------------------------------------*
* Select Sales Order Header Data from VBAK
*---------------------------------------------------------------------*

SELECT vbeln
       erdat
       erzet
       ernam
       vbtyp FROM vbak INTO TABLE it_vbak
          WHERE vbeln IN   s_vbeln .

*---------------------------------------------------------------------*
* Select Sales Order Item Data from VBAP
* FOR ALL ENTRIES is used to get items for selected sales orders
*---------------------------------------------------------------------*

IF  it_vbak IS NOT INITIAL .

  SELECT  vbeln
          posnr
          matnr FROM vbap INTO TABLE it_vbap
    FOR ALL ENTRIES IN it_vbak
     WHERE vbeln = it_vbak-vbeln .

ENDIF.

*---------------------------------------------------------------------*
* Combine Header and Item Data into Final Internal Table
*---------------------------------------------------------------------*

LOOP AT it_vbak INTO wa_vbak.

  LOOP AT it_vbap INTO wa_vbap WHERE vbeln = wa_vbak-vbeln.
    wa_final-vbeln = wa_vbak-vbeln .
    wa_final-erdat = wa_vbak-erdat .
    wa_final-erzet = wa_vbak-erzet .
    wa_final-ernam = wa_vbak-ernam .
    wa_final-vbtyp = wa_vbak-vbtyp .

    wa_final-posnr = wa_vbap-posnr .
    wa_final-matnr = wa_vbap-matnr .

    "Append combined data to final internal table
    APPEND wa_final TO it_final .

    "Clear work area after appending
    CLEAR : wa_final.

  ENDLOOP.

ENDLOOP.

*---------------------------------------------------------------------*
* Configure ALV Field Catalog
*---------------------------------------------------------------------*

LOOP AT lt_fieldcat INTO wa_fieldcat .

  "Configure Sales Document Number Column

  IF wa_fieldcat-fieldname = 'vbeln'.

     wa_fieldcat-col_pos = 3 .

    "Set Column Heading
    wa_fieldcat-seltext_l = 'DOCUMENT NUMBER'.



    MODIFY lt_fieldcat FROM wa_fieldcat TRANSPORTING seltext_l .

  ENDIF.

  "Configure Creation Date Column

  IF wa_fieldcat-fieldname = 'ERDAT'.

    wa_fieldcat-col_pos = 3 .

    MODIFY lt_fieldcat FROM wa_fieldcat TRANSPORTING col_pos .

  ENDIF.

  "Configure Creation Time Column

  IF wa_fieldcat-fieldname = 'ERZET'.

    wa_fieldcat-col_pos =  3 .

    MODIFY lt_fieldcat FROM wa_fieldcat TRANSPORTING col_pos .

  ENDIF.

ENDLOOP.

*---------------------------------------------------------------------*
* Configure ALV Sorting by Creation Date (Descending)
*---------------------------------------------------------------------*

wa_sort-fieldname ='ERDAT'.
wa_sort-down = 'X' .

APPEND wa_sort TO it_sort .

*---------------------------------------------------------------------*
* Generate ALV Field Catalog from Structure
*---------------------------------------------------------------------*

CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING
    i_structure_name = 'ZMA_ALV_STR'
  CHANGING
    ct_fieldcat      = lt_fieldcat.

IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.

*---------------------------------------------------------------------*
* Display ALV Grid
*---------------------------------------------------------------------*

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_program       = sy-repid
    i_callback_pf_status_set = 'PF_STATUS'
    i_callback_top_of_page   = 'TOP_PAGE'
   IT_FIELDCAT              = lt_fieldcat
    it_sort                  = it_sort
    it_filter                = it_filter

  TABLES
    t_outtab                 = it_final
  EXCEPTIONS
    program_error            = 1
    OTHERS                   = 2.

IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.

*---------------------------------------------------------------------*
* PF STATUS FORM
* Set Custom GUI Status for ALV Toolbar
*---------------------------------------------------------------------*

FORM pf_status USING rt_extab TYPE slis_t_extab.

  set PF-STATUS 'SALES' .

ENDFORM .

*---------------------------------------------------------------------*
* TOP OF PAGE FORM
* Display Report Header and Selection Information
*---------------------------------------------------------------------*

FORM top_page .

  "Main Report Heading
  wa_list-typ = 'H'.
  wa_list-info = 'Sales Order Display'.

  APPEND wa_list TO it_list .

  CLEAR: wa_list .

  "Display Selected Sales Order Range
  CONCATENATE s_vbeln-low 'to' s_vbeln-high
    INTO lv_input SEPARATED BY space .

  wa_list-typ = 'S'.
  wa_list-info = 'Sales Input'.
  wa_list-info = lv_input .

  APPEND wa_list TO it_list .

  CLEAR: wa_list .

  "Calculate Number of Records in Final Internal Table
  DESCRIBE TABLE it_final LINES lv_lines .

  CONCATENATE 'The Number of lines' lv_lines
    INTO lv_input SEPARATED BY space.

  wa_list-typ = 'A' .
  wa_list-info = lv_input .

  APPEND wa_list TO it_list .

  CLEAR: wa_list .
    wa_list-typ = 'S'.
  wa_list-key = 'DATA'.
  CONCATENATE sy-datum+6(2)
              sy-datum+4(2)
              sy-datum(4) INTO wa_list-info SEPARATED BY '/' .
  APPEND wa_list TO it_list .
  CLEAR wa_list.

  "Display Header Information in ALV
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = it_list.

ENDFORM.
