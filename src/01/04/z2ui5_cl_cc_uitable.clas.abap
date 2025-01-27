class Z2UI5_CL_CC_UITABLE definition
  public
  final
  create public .

public section.

  class-methods GET_JS
    returning
      value(RESULT) type STRING .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS Z2UI5_CL_CC_UITABLE IMPLEMENTATION.


  METHOD get_js.

    result = `if (!z2ui5.UITableExt) { sap.ui.define("z2ui5/UITableExt" , [` && |\n| &&
             `  "sap/ui/core/Control"` && |\n| &&
             `], (Control) => {` && |\n| &&
             `  "use strict";` && |\n| &&
             |\n| &&
             `  return Control.extend("z2ui5.UITableExt", {` && |\n| &&
             `      metadata: {` && |\n| &&
             `          properties: {` && |\n| &&
             `              tableId: { type: "String" }` && |\n| &&
             `          }` && |\n| &&
             `      },` && |\n| &&
             |\n| &&
             `      init() {` && |\n| &&
             `          sap.z2ui5.onBeforeRoundtrip.push(this.readFilter.bind(this));` && |\n| &&
             `          sap.z2ui5.onAfterRoundtrip.push(this.setFilter.bind(this));` && |\n| &&
             `      },` && |\n| &&
             |\n| &&
             `      readFilter() {` && |\n| &&
             `          try {` && |\n| &&
             `              let id = this.getProperty("tableId");` && |\n| &&
             `              let oTable = sap.z2ui5.oView.byId(id);` && |\n| &&
             `              this.aFilters = oTable.getBinding().aFilters;` && |\n| &&
             `          } catch (e) { };` && |\n| &&
             `      },` && |\n| &&
             |\n| &&
             `      setFilter() {` && |\n| &&
             `          try {` && |\n| &&
             `            setTimeout( (aFilters) => { let id = this.getProperty("tableId");` && |\n| &&
             `              let oTable = sap.z2ui5.oView.byId(id);` && |\n| &&
             `              oTable.getBinding().filter(aFilters);` && |\n| &&
             `        } , 100 , this.aFilters);  } catch (e) { };` && |\n| &&
             `      },` && |\n| &&
             |\n| &&
             `      renderer(oRM, oControl) {` && |\n| &&
             `      }` && |\n| &&
             `  });` && |\n| &&
             `}); }`.

  ENDMETHOD.
ENDCLASS.
