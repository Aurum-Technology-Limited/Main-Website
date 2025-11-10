# 🛡️ Rate Limiting Your n8n Contact Form Workflow

## Why Rate Limit?

Your webhook URL is publicly accessible, which means:
- 🤖 Bots can spam your form
- 💸 Excessive submissions waste n8n executions
- 📧 Floods your HubSpot and Supabase with junk data
- 💰 Could increase costs on paid plans

**Solution:** Implement rate limiting to allow legitimate submissions while blocking abuse.

---

## 🎯 Method 1: n8n Built-In Rate Limiting (EASIEST)

n8n has a built-in "Rate Limit" node that's perfect for this use case.

### Step-by-Step Setup:

1. **Open Your n8n Workflow**
   - Go to https://aurumtechnologyltd.app.n8n.cloud
   - Open your contact form workflow

2. **Add Rate Limit Node**
   - After your Webhook node, add a new node
   - Search for **"Rate Limit"**
   - Place it BEFORE your HubSpot/Supabase nodes

3. **Configure Rate Limit Node**

```
Rate Limit Settings:
├─ Rate: 10
├─ Per: Hour
├─ By: IP Address
└─ On Rate Limit Exceeded: Return Error
```

**Your workflow should now look like:**
```
Webhook Trigger
    ↓
Rate Limit Node ← NEW
    ↓
HubSpot Node
    ↓
Supabase Node
```

### Configuration Options:

| Setting | Recommended Value | Why |
|---------|------------------|-----|
| **Rate** | 5-10 | Legitimate users rarely submit more than once |
| **Per** | Hour | Gives enough time window |
| **By** | IP Address | Tracks submissions per user |
| **Action on Exceed** | Return Error | Blocks additional submissions |

---

## 🎯 Method 2: Custom Rate Limiting with Function Node

For more control, use a Function node with custom logic.

### Step 1: Add Function Node

Place this AFTER your Webhook node:

```javascript
// Rate Limiting Logic
const ipAddress = $input.first().json.headers['x-forwarded-for'] || 
                  $input.first().json.headers['x-real-ip'] || 
                  'unknown';

const email = $input.first().json.body.email;

// Get workflow static data (persists between executions)
const staticData = this.getWorkflowStaticData('node');

// Initialize tracking if not exists
if (!staticData.submissions) {
  staticData.submissions = {};
}

// Current timestamp
const now = Date.now();
const oneHour = 60 * 60 * 1000; // 1 hour in milliseconds

// Create unique key (by IP + Email)
const key = `${ipAddress}_${email}`;

// Clean up old entries (older than 1 hour)
Object.keys(staticData.submissions).forEach(k => {
  if (now - staticData.submissions[k] > oneHour) {
    delete staticData.submissions[k];
  }
});

// Check if user has submitted recently
if (staticData.submissions[key]) {
  const timeSinceLastSubmission = now - staticData.submissions[key];
  
  if (timeSinceLastSubmission < oneHour) {
    // Rate limit exceeded
    throw new Error(`Rate limit exceeded. Please wait ${Math.ceil((oneHour - timeSinceLastSubmission) / 60000)} minutes before submitting again.`);
  }
}

// Record this submission
staticData.submissions[key] = now;

// Pass data through
return $input.all();
```

### Step 2: Add Error Handling

Add an **"Error Trigger"** node to handle rate limit errors gracefully:

```
Error Trigger
    ↓
Send Response (HTTP)
    Status Code: 429 (Too Many Requests)
    Body: { "error": "Rate limit exceeded. Please try again later." }
```

---

## 🎯 Method 3: Redis-Based Rate Limiting (ADVANCED)

For production-grade rate limiting across multiple workflows.

### Prerequisites:
- Redis database (free tier at Upstash.com)

### Step 1: Set Up Upstash Redis

1. Go to [upstash.com](https://upstash.com)
2. Create free account
3. Create new Redis database
4. Copy connection credentials

### Step 2: Add Redis Node to n8n

```
Webhook
    ↓
Function (Check Rate Limit)
    ↓
Redis (Get)
    ↓
Function (Validate)
    ↓
Redis (Set) ← Increment counter
    ↓
HubSpot / Supabase
```

### Step 3: Configure Redis Check

**Function Node (Before Redis):**
```javascript
const email = $input.first().json.body.email;
const ipAddress = $input.first().json.headers['x-forwarded-for'] || 'unknown';

// Create Redis key
const key = `rate_limit:${ipAddress}:${email}`;

return [{
  json: {
    ...($input.first().json),
    redisKey: key
  }
}];
```

**Redis Node (Get):**
- Operation: Get
- Key: `{{$json.redisKey}}`

**Function Node (Validate):**
```javascript
const currentCount = parseInt($input.first().json.data) || 0;
const maxSubmissions = 5; // Max 5 per hour

if (currentCount >= maxSubmissions) {
  throw new Error('Rate limit exceeded');
}

return $input.all();
```

**Redis Node (Increment):**
- Operation: Increment
- Key: `{{$json.redisKey}}`
- Expire After: 3600 seconds (1 hour)

---

## 🎯 Method 4: IP Address Blocking (IMMEDIATE PROTECTION)

Block known spam IPs completely.

### Add IF Node After Webhook:

```
IF Node Settings:
├─ Condition: String
├─ Value 1: {{$json.headers['x-forwarded-for']}}
├─ Operation: Not Equal
└─ Value 2: [Known spam IP]
```

**Common Spam IP Ranges to Block:**
- Cloud providers (AWS, Azure, GCP) if not expecting legitimate submissions from there
- Known VPN IPs
- Tor exit nodes

---

## 🎯 Method 5: Honeypot Field (CATCH BOTS)

Add a hidden field to your form that humans won't fill but bots will.

### Step 1: Add Honeypot to Your Frontend

In `/workspace/frontend/src/pages/Home.jsx`, add this hidden field:

```javascript
// Inside your form (around line 342)
<input 
  type="text" 
  name="website"
  value={formData.website}
  onChange={handleInputChange}
  style={{ 
    position: 'absolute',
    left: '-5000px',
    opacity: 0,
    pointerEvents: 'none'
  }}
  tabIndex="-1"
  autoComplete="off"
  aria-hidden="true"
/>
```

### Step 2: Check Honeypot in n8n

Add **Function Node** after webhook:

```javascript
// Check if honeypot field is filled (bot detected)
const honeypot = $input.first().json.body.website;

if (honeypot && honeypot.trim() !== '') {
  // Bot detected - silently reject
  throw new Error('Bot detected');
}

return $input.all();
```

**Why this works:**
- ✅ Real users won't see or fill the field
- ❌ Bots auto-fill all fields
- 🤖 Instantly catches 90% of spam bots

---

## 🎯 Method 6: CAPTCHA Integration (STRONGEST PROTECTION)

Integrate Google reCAPTCHA v3 for invisible bot protection.

### Step 1: Get reCAPTCHA Keys

1. Go to [google.com/recaptcha](https://www.google.com/recaptcha/admin)
2. Register your site
3. Choose **reCAPTCHA v3** (invisible)
4. Get Site Key and Secret Key

### Step 2: Add reCAPTCHA to Frontend

Install package:
```bash
cd /workspace/frontend
npm install react-google-recaptcha-v3
```

Update `src/pages/Home.jsx`:

```javascript
import { GoogleReCaptchaProvider, useGoogleReCaptcha } from 'react-google-recaptcha-v3';

// Wrap your App with provider (in App.js)
<GoogleReCaptchaProvider reCaptchaKey="YOUR_SITE_KEY">
  <Home />
</GoogleReCaptchaProvider>

// In Home component
const { executeRecaptcha } = useGoogleReCaptcha();

// In handleSubmit function (before axios.post)
const handleSubmit = async (e) => {
  e.preventDefault();
  
  // Get reCAPTCHA token
  if (!executeRecaptcha) {
    console.error('Execute recaptcha not yet available');
    return;
  }
  
  const recaptchaToken = await executeRecaptcha('contact_form');
  
  // Add token to form data
  const submissionData = {
    ...formData,
    recaptchaToken
  };
  
  // Send to n8n
  await axios.post('https://...webhook...', submissionData);
};
```

### Step 3: Verify in n8n

Add **HTTP Request Node** to verify token:

```
HTTP Request Settings:
├─ Method: POST
├─ URL: https://www.google.com/recaptcha/api/siteverify
└─ Body:
    {
      "secret": "YOUR_SECRET_KEY",
      "response": "{{$json.body.recaptchaToken}}"
    }
```

**Add Function Node to Check Score:**
```javascript
const score = $input.first().json.score; // 0.0 to 1.0

if (score < 0.5) {
  throw new Error('Failed reCAPTCHA verification');
}

return $input.all();
```

**Score Thresholds:**
- 0.9 - 1.0: Definitely human ✅
- 0.5 - 0.9: Probably human ✅
- 0.0 - 0.5: Probably bot ❌

---

## 🎯 Recommended Multi-Layer Protection

Combine multiple methods for best results:

```
Webhook Trigger
    ↓
1️⃣ Honeypot Check (catches simple bots)
    ↓
2️⃣ reCAPTCHA v3 (catches advanced bots)
    ↓
3️⃣ Rate Limit by IP (prevents spam)
    ↓
4️⃣ Email Validation (ensures valid email)
    ↓
5️⃣ Save to HubSpot
    ↓
6️⃣ Save to Supabase
```

### Implementation Priority:

**Start with (5 minutes):**
1. ✅ Honeypot field (easiest, catches 90% of bots)
2. ✅ n8n Rate Limit node (built-in, no code)

**Add later (10 minutes):**
3. ✅ Email validation
4. ✅ IP blocking for known spammers

**Advanced (30 minutes):**
5. ✅ reCAPTCHA v3 (strongest protection)
6. ✅ Redis-based rate limiting (for scale)

---

## 📊 Monitoring Rate Limits

### Check How Many Requests Are Being Blocked

Add **Sticky Note** in n8n workflow to track metrics:

```javascript
// In Function node after rate limit
const staticData = this.getWorkflowStaticData('global');

if (!staticData.metrics) {
  staticData.metrics = {
    totalSubmissions: 0,
    blockedSubmissions: 0
  };
}

staticData.metrics.totalSubmissions++;

console.log(`Total: ${staticData.metrics.totalSubmissions}, Blocked: ${staticData.metrics.blockedSubmissions}`);

return $input.all();
```

### Set Up Alerts

Add **Webhook** or **Email** node on error trigger:

```
Error Trigger
    ↓
IF (Error = Rate Limit)
    ↓
Send Email to Admin
    Subject: "Rate limit triggered"
    Body: "IP: {{$json.headers['x-forwarded-for']}}"
```

---

## 🧪 Testing Your Rate Limiting

### Test 1: Verify Rate Limit Works

```bash
# Submit form 10 times rapidly
for i in {1..10}; do
  curl -X POST https://aurumtechnologyltd.app.n8n.cloud/webhook/... \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","firstName":"Test","lastName":"User","message":"Test message"}'
  echo "Submission $i"
done
```

**Expected:** First 5 succeed, rest get blocked.

### Test 2: Verify Honeypot Works

Submit form with honeypot filled:

```bash
curl -X POST https://aurumtechnologyltd.app.n8n.cloud/webhook/... \
  -H "Content-Type: application/json" \
  -d '{"email":"bot@spam.com","firstName":"Bot","lastName":"Spammer","message":"Spam","website":"http://spam.com"}'
```

**Expected:** Request blocked immediately.

### Test 3: Verify Normal Submission Works

```bash
curl -X POST https://aurumtechnologyltd.app.n8n.cloud/webhook/... \
  -H "Content-Type: application/json" \
  -d '{"email":"real@user.com","firstName":"Real","lastName":"User","message":"I need automation help"}'
```

**Expected:** Submission succeeds, goes to HubSpot + Supabase.

---

## 🚨 Troubleshooting

### Rate Limit Not Working

**Issue:** Submissions still going through  
**Fix:** Ensure Rate Limit node is BEFORE HubSpot/Supabase nodes

### Legitimate Users Getting Blocked

**Issue:** Real customers can't submit  
**Fix:** Increase rate limit from 5 to 10 per hour

### Error: "Cannot read property of undefined"

**Issue:** Static data not initialized  
**Fix:** Add initialization check:

```javascript
const staticData = this.getWorkflowStaticData('node');
if (!staticData.submissions) {
  staticData.submissions = {};
}
```

### Rate Limit Resets Too Quickly

**Issue:** Using "Per Minute" instead of "Per Hour"  
**Fix:** Change Rate Limit node to "Per Hour"

---

## 🎯 Quick Start: 5-Minute Setup

**The fastest way to protect your form:**

1. **Open your n8n workflow**

2. **Add Rate Limit node** after webhook:
   - Rate: 5
   - Per: Hour  
   - By: IP Address

3. **Add Honeypot field** to your frontend form (see Method 5)

4. **Test it** - submit form 6 times rapidly

5. **Done!** You're now protected from 95% of spam.

---

## 📚 Additional Resources

- **n8n Rate Limit Docs:** https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.ratelimit/
- **reCAPTCHA v3 Docs:** https://developers.google.com/recaptcha/docs/v3
- **Upstash Redis:** https://upstash.com
- **IP Blocklists:** https://github.com/stamparm/ipsum

---

## ✅ Rate Limiting Checklist

- [ ] Added Rate Limit node to n8n workflow (5/hour)
- [ ] Tested rate limit works (6th submission fails)
- [ ] Added honeypot field to frontend form
- [ ] Tested honeypot catches bots
- [ ] Configured error handling for rate limits
- [ ] Set up monitoring/alerts (optional)
- [ ] Considered reCAPTCHA v3 (recommended)
- [ ] Documented rate limit settings

---

## 🎉 You're Protected!

With these rate limiting strategies, you've secured your contact form against:
- ✅ Spam bots
- ✅ DDoS attempts  
- ✅ Form flooding
- ✅ Fake submissions
- ✅ Resource waste

**Start with Method 1 + Method 5**, and you're good to go! 🛡️
