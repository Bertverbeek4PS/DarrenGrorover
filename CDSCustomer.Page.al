page 50100 "CDS Account List"
{
    PageType = List;
    SourceTable = "CRM Account"; //Change to correct Dataverse Table
    Editable = false;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(AccountId; rec.AccountId)
                {
                    ApplicationArea = all;
                }
                field(Name; rec.Name)
                {
                    ApplicationArea = all;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(CreateFromCDS)
            {
                ApplicationArea = All;
                Caption = 'Create in Business Central';
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Generate the table from the coupled Microsoft Dataverse worker.';

                trigger OnAction()
                var
                    CDSCustomer: Record "CRM Account"; //Change to correct Dataverse Table
                    CRMIntegrationManagement: Codeunit "CRM Integration Management";
                begin
                    CurrPage.SetSelectionFilter(CDSCustomer);
                    CRMIntegrationManagement.CreateNewRecordsFromCRM(CDSCustomer);
                end;
            }
        }
    }

    var
        CurrentlyCoupledCDSCustomer: Record "CRM Account"; //Change to correct Dataverse Table

    trigger OnInit()
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");
    end;

    procedure SetCurrentlyCoupledCDSCustomer(CDSCustomer: Record "CRM Account") //Change to correct Dataverse Table
    begin
        CurrentlyCoupledCDSCustomer := CDSCustomer;
    end;
}