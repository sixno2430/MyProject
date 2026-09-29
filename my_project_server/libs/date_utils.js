// ============================================================
// date_utils.js — ฟังก์ชันช่วยจัดการวันที่ (ตอนนี้ยังไม่มีไฟล์ไหนเรียกใช้)
// ============================================================

module.exports = {
    /**
     * วันที่ปัจจุบันในรูปแบบ dd-mm-yyyy
     */
    getCurrentDateForToken: () => {
        const now = new Date();
        const formattedDate = new Intl.DateTimeFormat('en-GB', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        }).format(now).replace(/\//g, '-');

        return formattedDate;
    }
}