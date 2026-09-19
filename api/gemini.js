// وسيط Gemini على Vercel.
//
// نسخة الويب من التطبيق لا تحمل GEMINI_API_KEY، لأن كل ما يصل المتصفح قابل
// للقراءة. بدل ذلك تنادي الحزمة هذا المسار، والدالة تعيد إرسال الطلب إلى
// Google بعد إضافة المفتاح من متغيّرات بيئة Vercel.
//
// بقية المسار (models/<name>:generateContent) تصل في ?path= عبر قاعدة
// rewrite في vercel.json.

const UPSTREAM = 'https://generativelanguage.googleapis.com/v1beta';

// بدون هذا القيد تتحوّل الدالة إلى وسيط مفتوح يستطيع أي أحد استعماله
// لأي نداء على حساب المفتاح.
const ALLOWED_PATH = /^models\/[A-Za-z0-9._-]+:(generateContent|countTokens)$/;

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    res.status(405).json({ error: 'Method Not Allowed' });
    return;
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    res.status(500).json({
      error: 'GEMINI_API_KEY غير مضبوط في متغيّرات بيئة المشروع على Vercel',
    });
    return;
  }

  const path = String((req.query && req.query.path) || '');
  if (!ALLOWED_PATH.test(path)) {
    res.status(400).json({ error: `مسار غير مسموح به: ${path}` });
    return;
  }

  const body =
    typeof req.body === 'string' ? req.body : JSON.stringify(req.body ?? {});

  try {
    const upstream = await fetch(`${UPSTREAM}/${path}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
      body,
    });

    const text = await upstream.text();
    res.status(upstream.status);
    res.setHeader(
      'content-type',
      upstream.headers.get('content-type') || 'application/json',
    );
    res.send(text);
  } catch (error) {
    res.status(502).json({ error: `تعذّر الوصول إلى Gemini: ${error.message}` });
  }
};
