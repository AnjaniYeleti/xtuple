
CREATE OR REPLACE FUNCTION formatDate(TIMESTAMP WITH TIME ZONE) RETURNS TEXT IMMUTABLE AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
  SELECT TO_CHAR($1, COALESCE((SELECT locale_dateformat
                                 FROM locale
                                 JOIN usrpref ON locale_id = usrpref_value::integer
                                             AND usrpref_name = 'locale_id'
                                WHERE usrpref_username = getEffectiveXtUser()),
                              'yyyy-mm-dd')) AS result
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION formatDate(DATE) RETURNS TEXT IMMUTABLE AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
  SELECT TO_CHAR($1, COALESCE((SELECT locale_dateformat
                                 FROM locale
                                 JOIN usrpref ON locale_id = usrpref_value::integer
                                             AND usrpref_name = 'locale_id'
                               WHERE usrpref_username = getEffectiveXtUser()),
                              'yyyy-mm-dd')) AS result
$$ LANGUAGE sql;

--DROP FUNCTION IF EXISTS formatDate(DATE, TEXT);
CREATE OR REPLACE FUNCTION formatDate(pDate DATE, pString TEXT) RETURNS TEXT IMMUTABLE AS $$
-- Copyright (c) 1999-2019 by OpenMFG LLC, d/b/a xTuple.
-- See www.xtuple.com/CPAL for the full text of the software license.
BEGIN
  IF pDate = startOfTime() OR pDate = endOfTime() OR pDate IS NULL THEN
    RETURN pString;
  ELSE
    RETURN formatDate(pDate);
  END IF;
END;
$$ LANGUAGE plpgsql;

