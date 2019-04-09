CREATE OR REPLACE FUNCTION releaseTaskNumber(TEXT) RETURNS BOOLEAN AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
  SELECT releaseNumber('TaskNumber', $1::INTEGER) > 0;
$$ LANGUAGE sql;