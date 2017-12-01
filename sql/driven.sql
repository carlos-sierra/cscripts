/* performScanQuery(leases,HashRangeIndex) */
SELECT
  currentOwner,
  id,
  KievTxnID,
  leaseTypeId,
  previousKievTxTimestamp,
  renewable
FROM
  compute_wf.leases
WHERE
  (leaseTypeId, id, KievTxnID, 1) IN (
    SELECT
      leaseTypeId,
      id,
      KievTxnID,
      ROW_NUMBER() OVER (
        PARTITION BY leaseTypeId,
        id
        ORDER BY
          KievTxnID DESC
      ) rn
    FROM
      compute_wf.leases
    WHERE
      KievTxnID <= &&b1.
  )
  AND KievLive = 'Y'
  AND ((leaseTypeId = 'terminateWindowsBmInstance:6:0:AwaitConsoleHistory:?'))
ORDER BY
  leaseTypeId ASC,
  id ASC FETCH FIRST 100 ROWS ONLY
/
