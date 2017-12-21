/* performScanQuery(leases,HashRangeIndex) */
SELECT
  currentOwner,
  id,
  KievTxnID,
  leaseTypeId,
  previousKievTxTimestamp,
  renewable
FROM
  storewf.leases
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
      storewf.leases
    WHERE
      KievTxnID <= &&b1.
  )
  AND KievLive = 'Y'
  AND ((leaseTypeId = 'create-volume-v2:2:1:CREATE_VOLUME_REQUEST:?'))
ORDER BY
  leaseTypeId ASC,
  id ASC FETCH FIRST 100 ROWS ONLY
/
