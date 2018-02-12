(function () {
  "use strict";

  var DEBUG = false,
    _      = require("underscore"),
    assert = require('chai').assert,
    dblib  = require('../dblib'),
    datasource = dblib.datasource,
    adminCred = dblib.generateCreds();

  // TODO - write test for:
  // - shipShipment(integer)

  describe("shipShipment(integer, timestamp with time zone)", function () {
    this.timeout(10 * 1000);

    var params = {
      itemNumber: "BTRUCK1",
      whCode: "WH1",
      qty: 1
    };
    var itemlocseries, numUnpostedInvHist;

    it("should get the itemsite_id and qoh",function (done) {
      var sql = "SELECT itemsite_qtyonhand, itemsite_id, itemsite_warehous_id" +
                "  FROM itemsite" +
                " WHERE itemsite_id = getitemsiteid($1, $2);",
        options = _.extend({}, adminCred, { parameters: [ params.whCode, params.itemNumber ]});

      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.operator(res.rows[0].itemsite_id, ">", 0);
        params.qohBefore = res.rows[0].itemsite_qtyonhand;
        params.itemsiteId = res.rows[0].itemsite_id;
        params.whId = res.rows[0].itemsite_warehous_id;
        done();
      });
    });

    it("needs the number of unposted invhist records", function (done) {
      var sql = "SELECT COUNT(*) AS num FROM invhist WHERE NOT invhist_posted;";

      datasource.query(sql, adminCred, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        numUnpostedInvHist = res.rows[0].num;
        done();
      });
    });

    it("needs a sales order", function (done) {
     var callback = function (result) {
        assert.isNotNull(result);
        assert.operator(result.cohead_id, '>', 0, 'cohead_id is greater than 0');
        params.coheadId = result.cohead_id;
        done();
      };

      dblib.createSalesOrder(callback);
    });

    it("needs a sales order line item",function (done) {
      var callback = function (result) {
        params.coitemId = result;
        done();
      };

      dblib.createSalesOrderLineItem(params, callback);
    });

    // Note: Don't handle distribution detail here, that will be done in private-extensions/test/inventory

    it("issuetoshipping() should succeed", function (done) {
      var sql = "SELECT issueToShipping($1::integer, $2::numeric) AS result;",
        options = _.extend({}, adminCred, { parameters: [ params.coitemId, params.qty ]});

      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        itemlocseries = res.rows[0].result;
        assert.operator(itemlocseries, ">", 0);
        done();
      });
    });

    it("needs the issuetoshipping itemlocseries posted", function (done) {
      var sql     = "SELECT postItemLocSeries($1) AS result;",
          options = _.extend({}, adminCred, { parameters: [ itemlocseries ]});
      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.isTrue(res.rows[0].result);
        done();
      });
    });

    it("check that qoh was updated", function (done) {
      var sql = "SELECT itemsite_qtyonhand AS result" +
                "  FROM itemsite" +
                " WHERE itemsite_id=$1::integer;",
        options = _.extend({}, adminCred, { parameters: [ params.itemsiteId ]});

      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.equal(res.rows[0].result, params.qohBefore - params.qty);
        done();
      });
    });

    it("should have a shiphead_id", function (done) {
      var sql = "SELECT getOpenShipmentId('SO', $1, $2) AS result;",
        options = _.extend({}, adminCred, { parameters: [ params.coheadId, params.whId ]});

      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.operator(res.rows[0].result, ">", 0);
        params.shipheadId = res.rows[0].result;
        done();
      });
    });

    it.skip("shipShipment() should fail if sales order is on hold");
    it.skip("shipShipment() should fail if impartially shipped kit item");
    it.skip("shipShipment() should fail if flagged as ship complete and has items yet to be shipped");
    it.skip("shipShipment() should not succeed if already shipped");

    it("shipShipment() should succeed", function (done) {
      var sql = "SELECT shipShipment($1, current_timestamp) AS result;",
        options = _.extend({}, adminCred, { parameters: [ params.shipheadId ]});

      datasource.query(sql, options, function (err, res) {
        if (DEBUG)
          console.log("shipShipment result: ", res.rows[0].result);
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        itemlocseries = res.rows[0].result;
        assert.operator(itemlocseries, ">", 0);
        done();
      });
    });

    it("needs the shipShipment itemlocseries posted", function (done) {
      var sql     = "SELECT postItemLocSeries($1) AS result;",
          options = _.extend({}, adminCred, { parameters: [ itemlocseries ]});
      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.isTrue(res.rows[0].result);
        done();
      });
    });

    it("shiphead_shipped should be true", function (done) {
      var sql = "SELECT shiphead_shipped AS result" +
                "  FROM shiphead WHERE shiphead_id = $1;",
        options = _.extend({}, adminCred, { parameters: [ params.shipheadId ]});

      datasource.query(sql, options, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.equal(res.rows[0].result, true);
        done();
      });
    });

    it("there should be no new unposted invhist records", function (done) {
      var sql = "SELECT COUNT(*) AS num FROM invhist WHERE NOT invhist_posted;";

      datasource.query(sql, adminCred, function (err, res) {
        assert.isNull(err);
        assert.equal(res.rowCount, 1);
        assert.equal(res.rows[0].num, numUnpostedInvHist);
        done();
      });
    });

  });
}());

