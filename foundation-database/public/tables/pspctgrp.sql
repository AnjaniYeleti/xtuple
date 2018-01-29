SELECT xt.create_table('pspctgrp', 'public', false, 'groups');

SELECT
  xt.add_constraint('pspctgrp', 'pspctgrp_pkey', 'PRIMARY KEY (groups_id)', 'public'),
  xt.add_constraint('pspctgrp', 'pspctgrp_groups_name_check', $$CHECK (groups_name <> ''::text)$$, 'public');

COMMENT ON TABLE public.pspctgrp
  IS 'Prospect Groups';

