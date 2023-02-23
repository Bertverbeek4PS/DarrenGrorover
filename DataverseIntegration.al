codeunit 50100 "Dataverse Integration"
{
    //Code below is for looking up a record inside
    //BEGIN
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Lookup CRM Tables", 'OnLookupCRMTables', '', true, true)]
    local procedure HandleOnLookupCRMTables(CRMTableID: Integer; NAVTableId: Integer; SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text; var Handled: Boolean)
    begin
        if CRMTableID = Database::"CRM Account" then //Change to correct Dataverse Table
            Handled := LookupCDSCustomer(SavedCRMId, CRMId, IntTableFilter);
    end;

    local procedure LookupCDSCustomer(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CDSCustomer: Record "CRM Account"; //Change to correct Dataverse Table
        OriginalCDSCustomer: Record "CRM Account"; //Change to correct Dataverse Table
        CDSCustomerList: Page "CDS Account List"; //Create your own lookuppage
    begin
        if not IsNullGuid(CRMId) then begin
            if CDSCustomer.Get(CRMId) then
                CDSCustomerList.SetRecord(CDSCustomer);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCDSCustomer.Get(SavedCRMId) then
                    CDSCustomerList.SetCurrentlyCoupledCDSCustomer(OriginalCDSCustomer);
        end;

        CDSCustomer.SetView(IntTableFilter);
        CDSCustomerList.SetTableView(CDSCustomer);
        CDSCustomerList.LookupMode(true);
        if CDSCustomerList.RunModal = ACTION::LookupOK then begin
            CDSCustomerList.GetRecord(CDSCustomer);
            CRMId := CDSCustomer.AccountId; //Primary Key of the CDS Table
            exit(true);
        end;
        exit(false);
    end;
    //END

    //Code below is for coupling tables and fields
    //BEGIN 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", 'OnGetCDSTableNo', '', false, false)]
    local procedure HandleOnGetCDSTableNo(BCTableNo: Integer; var CDSTableNo: Integer; var handled: Boolean)
    begin
        if BCTableNo = DATABASE::Customer then begin
            CDSTableNo := DATABASE::"CRM Account"; //Change to correct Dataverse Table
            handled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", 'OnAddEntityTableMapping', '', true, true)]
    local procedure HandleOnAddEntityTableMapping(var TempNameValueBuffer: Record "Name/Value Buffer" temporary);
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        CRMSetupDefaults.AddEntityTableMapping('CUSTOMER', DATABASE::Customer, TempNameValueBuffer);
        CRMSetupDefaults.AddEntityTableMapping('CUSTOMER', DATABASE::"CRM Account", TempNameValueBuffer); //Change to correct Dataverse Table
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnHasCompanyIdField', '', false, false)]
    local procedure HandleOnHasCompanyIdField(TableId: Integer; var HasField: Boolean)
    begin
        if TableId = Database::"CRM Account" then //Change to correct Dataverse Table
            HasField := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Setup Defaults", 'OnAfterResetConfiguration', '', true, true)]
    local procedure HandleOnAfterResetConfiguration(CDSConnectionSetup: Record "CDS Connection Setup")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CDSCustomer: Record "CRM Account"; //Change to correct Dataverse Table
        Customer: Record Customer;
    begin
        //For table record
        InsertIntegrationTableMapping(IntegrationTableMapping, 'CUSTOMER', DATABASE::Employee, DATABASE::"CRM Account", CDSCustomer.FieldNo(AccountId), CDSCustomer.FieldNo(ModifiedOn), '', '', true);
        //For field mapping you can add more as you like. Example is field name
        InsertIntegrationFieldMapping('CUSTOMER', Customer.FieldNo(Name), CDSCustomer.FieldNo(Name), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnBeforeHandleCustomIntegrationTableMapping', '', false, false)]
    local procedure HandleCustomIntegrationTableMappingReset(var IsHandled: Boolean; IntegrationTableMappingName: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CDSCustomer: Record "CRM Account"; //Change to correct Dataverse Table
        Customer: Record Customer;
    begin
        case IntegrationTableMappingName of
            'CUSTOMER':
                begin
                    //For table record
                    InsertIntegrationTableMapping(IntegrationTableMapping, 'CUSTOMER', DATABASE::Customer, DATABASE::"CRM ACcount", CDSCustomer.FieldNo(AccountId), CDSCustomer.FieldNo(ModifiedOn), '', '', true);
                    //For field mapping you can add more as you like. Example is field name
                    InsertIntegrationFieldMapping('CUSTOMER', Customer.FieldNo(Name), CDSCustomer.FieldNo(Name), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
                    IsHandled := true;
                end;
        end;
    end;

    local procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean)
    begin
        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo, IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode, SynchOnlyCoupledRecords, IntegrationTableMapping.Direction::Bidirectional, 'CDS');
    end;

    procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
            ConstValue, ValidateField, ValidateIntegrationTableField);
    end;
    //END
}