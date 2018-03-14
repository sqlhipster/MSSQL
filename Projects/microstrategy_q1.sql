select      a11.Reporting_Month_ID  Reporting_Month_ID,
                a13.Portfolio_Name  Portfolio_Name,
                a11.Portfolio  Portfolio,
                a12.Change_Order  Change_Order,
                a12.Date_Of_Change  Date_Of_Change,
                a12.ACH_File_Daily_Xfer_Limit  ACH_File_Daily_Xfer_Limit,
                (sum(a11.Current_Demand_Total) * 1.0)  WJXBFS1
--into ZZSP00
from         mvw_ACH_RDC_Clients       a11
                join          mvw_ACH_RDC_Limits         a12
                  on          (a11.Client_ID = a12.Client_ID)
                join          mvw_LU_Clients    a13
                  on          (a11.Client_ID = a13.Client_ID and 
                a11.DDA_Account = a13.DDA_Account and 
                a11.Portfolio = a13.Portfolio and 
                a11.Relationship_Name = a13.Relationship_Name)
where      (a12.ACH_File_Daily_Xfer_Limit > 0
and a12.Change_Order in (1)
and a11.Client_ID not in ('7231', '7237', '10', '100', '101', '10001', '99999', '10000', '100011', '10002', '10085', '10073', '30291', '8339', '100851', '10181', '10122', '10552', '100852'))
group by a11.Reporting_Month_ID,
                a13.Portfolio_Name,
                a11.Portfolio,
                a12.Change_Order,
                a12.Date_Of_Change,
                a12.ACH_File_Daily_Xfer_Limit 