class Z2UI5_CL_CORE_JSON_SRV definition
  public
  final
  create public .

public section.

  interfaces Z2UI5_IF_AJSON_FILTER .

  methods REQUEST_JSON_TO_ABAP
    importing
      !VAL type STRING
    returning
      value(RESULT) type Z2UI5_IF_CORE_TYPES=>TY_S_HTTP_REQUEST_POST .
  methods RESPONSE_ABAP_TO_JSON
    importing
      !VAL type Z2UI5_IF_CORE_TYPES=>TY_S_HTTP_RESPONSE_POST
    returning
      value(RESULT) type STRING .
  methods MODEL_FRONT_TO_BACK
    importing
      !VIEW type STRING
      !T_ATTRI type ref to Z2UI5_IF_CORE_TYPES=>TY_T_ATTRI
      !MODEL type ref to Z2UI5_IF_AJSON .
  methods MODEL_BACK_TO_FRONT
    importing
      !T_ATTRI type ref to Z2UI5_IF_CORE_TYPES=>TY_T_ATTRI
    returning
      value(RESULT) type STRING .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS Z2UI5_CL_CORE_JSON_SRV IMPLEMENTATION.


  METHOD model_front_to_back.

    IF line_exists( t_attri->*[ view = view ] ).
      DATA(lv_view) = view.
    ELSE.
      lv_view = z2ui5_if_client=>cs_view-main.
    ENDIF.

    LOOP AT t_attri->* REFERENCE INTO DATA(lr_attri)
      WHERE bind_type = z2ui5_if_core_types=>cs_bind_type-two_way
      AND  view  = lv_view.
      TRY.

          DATA(lo_val_front) = model->slice( lr_attri->name_client ).
          IF lo_val_front IS NOT BOUND.
            CONTINUE.
          ENDIF.

          IF lr_attri->custom_mapper_back IS BOUND.
            lo_val_front = lo_val_front->map( lr_attri->custom_mapper_back ).
          ENDIF.

          IF lr_attri->custom_filter_back IS BOUND.
            lo_val_front = lo_val_front->filter( lr_attri->custom_filter_back ).
          ENDIF.

          ASSIGN lr_attri->r_ref->* TO FIELD-SYMBOL(<val>).

          lo_val_front->to_abap(
            IMPORTING
              ev_container = <val> ).

        CATCH cx_root INTO DATA(x).
          ASSERT x IS BOUND.
      ENDTRY.
    ENDLOOP.


  ENDMETHOD.


  METHOD model_back_to_front.
    TRY.

        DATA(ajson_result) = CAST z2ui5_if_ajson( z2ui5_cl_ajson=>create_empty( ) ).
        LOOP AT t_attri->* REFERENCE INTO DATA(lr_attri) WHERE bind_type <> ``.

          IF lr_attri->custom_mapper IS BOUND.
            DATA(ajson) = CAST z2ui5_if_ajson( z2ui5_cl_ajson=>create_empty( ii_custom_mapping = lr_attri->custom_mapper ) ).
          ELSE.
            ajson = CAST z2ui5_if_ajson( z2ui5_cl_ajson=>create_empty( ii_custom_mapping = z2ui5_cl_ajson_mapping=>create_upper_case( ) ) ).
          ENDIF.

          CASE lr_attri->bind_type.
            WHEN z2ui5_if_core_types=>cs_bind_type-one_way
            OR z2ui5_if_core_types=>cs_bind_type-two_way.

              ASSIGN lr_attri->r_ref->* TO FIELD-SYMBOL(<attribute>).
              ASSERT sy-subrc = 0.
              ajson->set( iv_ignore_empty = abap_false iv_path = `/` iv_val =  <attribute> ).

            WHEN z2ui5_if_core_types=>cs_bind_type-one_time.
              ajson->set( iv_ignore_empty = abap_false iv_path = `/` iv_val = lr_attri->json_bind_local ).

            WHEN OTHERS.
              ASSERT `` = `ERROR_UNKNOWN_BIND_MODE`.
          ENDCASE.

          IF lr_attri->custom_filter IS BOUND.
            ajson = ajson->filter( lr_attri->custom_filter ).
          ENDIF.

          ajson_result->set( iv_path = lr_attri->name_client iv_val = ajson ).
        ENDLOOP.

        result = ajson_result->stringify( ).
        result = COND #( WHEN result IS INITIAL THEN `{}` ELSE result ).

      CATCH cx_root INTO DATA(x).
        ASSERT x IS NOT BOUND.
    ENDTRY.
  ENDMETHOD.


  METHOD request_json_to_abap.
    TRY.

        DATA(lo_ajson) = CAST z2ui5_if_ajson( z2ui5_cl_ajson=>parse( val ) ).

        DATA(lv_model_edit_name) = `/` && z2ui5_if_core_types=>cs_ui5-two_way_model.

        result-o_model = z2ui5_cl_ajson=>create_empty( ).
        DATA(lo_model) = lo_ajson->slice( lv_model_edit_name ).
        result-o_model->set( iv_path = lv_model_edit_name iv_val = lo_model ).
        lo_ajson->delete( lv_model_edit_name ).

        lo_ajson = lo_ajson->slice( `/S_FRONT` ).
        lo_ajson->to_abap(
            EXPORTING
               iv_corresponding = abap_true
            IMPORTING
                ev_container    = result-s_front ).

        result-s_front-o_comp_data = lo_ajson->slice( `/COMPDATA` ).

        result-s_control-check_launchpad = xsdbool( result-s_front-search CS `scenario=LAUNCHPAD` or result-s_front-pathname CS `/ui2/flp`).
        IF result-s_front-id IS NOT INITIAL.
          RETURN.
        ENDIF.

        TRY.
            DATA(lo_comp) = result-s_front-o_comp_data.
            result-s_control-app_start = lo_comp->get( `/startupParameters/app_start/1` ).
            result-s_control-app_start = z2ui5_cl_util=>c_trim_upper( result-s_control-app_start ).
          CATCH cx_root.
        ENDTRY.

        IF result-s_control-app_start IS NOT INITIAL.
          IF result-s_control-app_start(1) = `-`.
            REPLACE FIRST OCCURRENCE OF `-` IN result-s_control-app_start WITH `/`.
            REPLACE FIRST OCCURRENCE OF `-` IN result-s_control-app_start WITH `/`.
          ENDIF.
          RETURN.
        ENDIF.

        result-s_control-app_start = z2ui5_cl_util=>c_trim_upper(
        z2ui5_cl_util=>url_param_get( val = `app_start` url = result-s_front-search ) ).

      CATCH cx_root INTO DATA(x).
        RAISE EXCEPTION TYPE z2ui5_cx_util_error
          EXPORTING
            val = x.
    ENDTRY.
  ENDMETHOD.


  METHOD response_abap_to_json.
    TRY.

        DATA(ajson_result) = CAST z2ui5_if_ajson( z2ui5_cl_ajson=>create_empty(
          ii_custom_mapping = z2ui5_cl_ajson_mapping=>create_upper_case( ) ) ).

        ajson_result->set( iv_path = `/` iv_val = val-s_front ).
        ajson_result = ajson_result->filter( NEW z2ui5_cl_core_json_srv( ) ).
        DATA(lv_frontend) = ajson_result->stringify( ).

        result = `{` &&
            |"S_FRONT":{ lv_frontend },| &&
            |"MODEL":{ val-model }| &&
          `}`.

      CATCH cx_root INTO DATA(x).
        ASSERT x IS NOT BOUND.
    ENDTRY.
  ENDMETHOD.


  METHOD z2ui5_if_ajson_filter~keep_node.

    rv_keep = abap_true.

    CASE iv_visit.

      WHEN z2ui5_if_ajson_filter=>visit_type-value.

        CASE is_node-type.
          WHEN z2ui5_if_ajson_types=>node_type-boolean.
            IF is_node-value = `false`.
              rv_keep = abap_false.
            ENDIF.
          WHEN z2ui5_if_ajson_types=>node_type-number.
            IF is_node-value = `0`.
              rv_keep = abap_false.
            ENDIF.
          WHEN z2ui5_if_ajson_types=>node_type-string.
            IF is_node-value = ``.
              rv_keep = abap_false.
            ENDIF.
        ENDCASE.

      WHEN z2ui5_if_ajson_filter=>visit_type-close.

        IF is_node-children = 0.
          rv_keep = abap_false.
        ENDIF.

    ENDCASE.

  ENDMETHOD.
ENDCLASS.
