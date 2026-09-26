(function () {
  const pathParts = window.location.pathname.split('/').filter(Boolean);
  const quoteIndex = pathParts.indexOf('quote');
  const queryQuote = new URLSearchParams(window.location.search).get('quote');
  const quoteId = quoteIndex >= 0 ? pathParts[quoteIndex + 1] : queryQuote;
  if (!quoteId) return;

  const fallbackQuotes = {
    'quote-1': {
      textEnglish: 'Remember the Guru with a simple heart, and every step becomes worship.',
      textHindi: 'सरल हृदय से गुरु-स्मरण करें; प्रत्येक चरण पूजा बन जाता है।'
    },
    'quote-2': {
      textEnglish: 'When the day opens and closes in satsang, the heart becomes gentle.',
      textHindi: 'दिवस का आरंभ और समापन सत्संग में हो तो हृदय कोमल हो जाता है।'
    },
    'quote-3': {
      textEnglish: 'Meditation is not withdrawal from life; it is a return to the divine light within.',
      textHindi: 'ध्यान जीवन से विमुखता नहीं; यह अंतःस्थित दिव्य प्रकाश में पुनरागमन है।'
    }
  };

  const landingPage = document.getElementById('landing-page');
  const quotePage = document.getElementById('quote-page');
  if (landingPage) landingPage.hidden = true;
  if (quotePage) quotePage.hidden = false;
  document.body.classList.add('showing-quote-page');

  const canonicalUrl = `https://guruvandan.com/quote/${encodeURIComponent(quoteId)}/`;
  const canonical = document.querySelector('link[rel="canonical"]');
  const openGraphUrl = document.querySelector('meta[property="og:url"]');
  if (canonical) canonical.href = canonicalUrl;
  if (openGraphUrl) openGraphUrl.content = canonicalUrl;

  const englishNode = document.getElementById('quote-english');
  const hindiNode = document.getElementById('quote-hindi');
  const englishAuthorNode = document.getElementById('quote-author-english');
  const hindiAuthorNode = document.getElementById('quote-author-hindi');

  function normalizedAuthor(value) {
    const author = String(value || '').trim();
    if (!author || author === 'Sadguru Maharaj') return 'Maharshi Mehi Paramhans';
    return author;
  }

  function normalizedHindiAuthor(value) {
    const author = String(value || '').trim();
    if (!author || author === 'सद्गुरु महाराज') return 'महर्षि मेँहीँ परमहंस';
    return author;
  }

  function renderQuote(value) {
    const fallback = fallbackQuotes[quoteId] || {};
    const english = String(value && (value.textEnglish || value.text) || fallback.textEnglish || '').trim();
    const hindi = String(value && value.textHindi || fallback.textHindi || '').trim();
    const authorEnglish = normalizedAuthor(value && (value.authorEnglish || value.author));
    const authorHindi = normalizedHindiAuthor(value && value.authorHindi);

    englishNode.textContent = english || 'This shared quote is not available.';
    hindiNode.textContent = hindi || 'यह साझा वचन उपलब्ध नहीं है।';
    englishAuthorNode.textContent = authorEnglish;
    hindiAuthorNode.textContent = authorHindi;
    document.title = `${english || 'Guru Vani'} | Guru Vandan`;
  }

  const endpoint =
    'https://guru-vandan-default-rtdb.asia-southeast1.firebasedatabase.app/' +
    `quotes/${encodeURIComponent(quoteId)}.json`;

  fetch(endpoint, { cache: 'no-store' })
    .then(function (response) {
      if (!response.ok) throw new Error('Quote request failed');
      return response.json();
    })
    .then(renderQuote)
    .catch(function () {
      renderQuote(null);
    });
})();
