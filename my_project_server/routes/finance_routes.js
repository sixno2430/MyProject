// ============================================================
// finance_routes.js — API รายรับ-รายจ่าย
//
// GET /api/finance/transactions, POST /api/finance/add, PUT/DELETE /api/finance/:finance_id
// (ผูกกับแอปใน server.js ด้วย app.use(...) — path เต็มเขียนไว้ในแต่ละ route)
// ============================================================

const express = require('express');
const finance = require('../models/finance');
const { logIfOk } = require('../libs/log_action');

const router = express.Router();

/** รายการเงิน ?month= &type=income|expense|all &user_id= */
router.get('/api/finance/transactions', async (req, res) => {
  try {
    const { month, type, user_id } = req.query;
    const result = await finance.getTransactions(month, type, user_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** บันทึกรายการเงินใหม่ */
router.post('/api/finance/add', async (req, res) => {
  try {
    const result = await finance.createTransaction(req.body);
    logIfOk(result, req.body.user_id, 'ADD_FINANCE', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** แก้ไขรายการเงิน (เฉพาะ FN...) */
router.put('/api/finance/:finance_id', async (req, res) => {
  try {
    const result = await finance.updateTransaction(req.params.finance_id, req.body.user_id, req.body);
    logIfOk(result, req.body.user_id, 'EDIT_FINANCE', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

/** ลบรายการเงิน (เฉพาะ FN...) ?user_id= */
router.delete('/api/finance/:finance_id', async (req, res) => {
  try {
    const result = await finance.deleteTransaction(req.params.finance_id, req.query.user_id);
    logIfOk(result, req.query.user_id, 'DELETE_FINANCE', req);
    res.json(result);
  } catch (error) {
    res.status(500).json({ isError: true, errorMessage: error.message });
  }
});

module.exports = router;
