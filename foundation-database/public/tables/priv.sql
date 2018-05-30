SELECT xt.create_table('priv', 'public');

ALTER TABLE public.priv DISABLE TRIGGER ALL;

SELECT
  xt.add_column('priv', 'priv_id',    'SERIAL', 'PRIMARY KEY NOT NULL', 'public'),
  xt.add_column('priv', 'priv_module',  'TEXT', NULL, 'public'),
  xt.add_column('priv', 'priv_name',    'TEXT', NULL, 'public'),
  xt.add_column('priv', 'priv_descrip', 'TEXT', NULL, 'public'),
  xt.add_column('priv', 'priv_seq',  'INTEGER', NULL, 'public');

-- add necessary privs in the absence of xt.add_priv
do $$
declare
  _privs TEXT[] := ARRAY[
      ['Accounting', 'ChangeCashRecvPostDate', 'Can change the distribution date when posting Cash Receipts'],
      ['Sales', 'OverrideSOHoldType', 'Allowed to override the Sales Order Hold Type'],
      ['Accounting', 'CreditMemoItemAccountOverride', 'Allows to override credit memo item revenue account'],
      ['System','AllowSharedFilterEdit', 'Allows to create and edit shared filters'],
      ['Sales','MaintainSimpleSalesOrders', 'Can add Simple Sales Orders'],
      ['Purchase', 'MaintainPurchaseTypes', 'Can Maintain Purchase Types'],
      ['Purchase', 'ViewPurchaseTypes', 'Can View Purchase Types'],
      ['Accounting', 'ReverseARApplication', 'Allows A/R Applications to be reversed'],
      ['Accounting', 'ReverseAPApplication', 'Allows A/P Applications to be reversed'],
      ['CRM', 'MaintainCRMRoles', 'Allows Maintenance of CRM Roles'],
      ['CRM', 'ViewCRMRoles', 'Can View CRM Roles'],
      ['CRM', 'MaintainTaskTemplates', 'Can maintain Task templates and template tasks'],
      ['CRM', 'MaintainAccountGroups', 'Allows Maintenance of CRM Account Groups'],
      ['CRM', 'ViewAccountGroups', 'Allows Viewing of CRM Account Groups'],
      ['CRM', 'MaintainAddressGroups', 'Allows Maintenance of Address Groups'],
      ['CRM', 'ViewAddressGroups', 'Allows Viewing of Address Groups'],
      ['CRM', 'MaintainProspectGroups', 'Allows Maintenance of Prospect Groups'],
      ['CRM', 'ViewProspectGroups', 'Allows Viewing of Prospect Groups'],
      ['CRM', 'MaintainContactGroups', 'Allows Maintenance of Contact Groups'],
      ['CRM', 'ViewContactGroups', 'Allows Viewing of Contact Groups'],
      ['CRM', 'MaintainDynamicFilters', 'Allows Maintenance of dynamic filters for CRM Groups']
    ];
  _p TEXT[];
begin
  foreach _p slice 1 in array _privs loop
    if not exists(select 1 from priv where priv_name = _p[2]) then
      insert into public.priv (priv_module, priv_name, priv_descrip)
                      values (_p[1],        _p[2],    _p[3]);
    end if;
    perform grantPriv('admin', _p[1]);
  end loop;
end
$$ language plpgsql;

SELECT grantPrivToAll('AllowSharedFilterEdit');

ALTER TABLE public.priv ENABLE TRIGGER ALL;

COMMENT ON TABLE priv IS 'System Privilege information';
