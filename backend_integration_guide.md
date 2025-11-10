# Backend Integration Guide
**Connecting Your Landing Page Form to Supabase**

---

## 📋 **OVERVIEW**

Your current setup:
- ✅ Frontend form sends data to n8n webhook
- ✅ n8n webhook forwards to HubSpot
- 🔄 **NEW:** Also save to Supabase database

---

## 🎯 **INTEGRATION STRATEGY**

### Option 1: n8n → Supabase (RECOMMENDED)
**Route:** Form → n8n → [HubSpot + Supabase]

**Advantages:**
- Centralized workflow management
- Easy to modify and monitor
- No backend code changes needed
- Can add data transformations

**How to implement:**
1. In your n8n workflow, add a Supabase node after the webhook trigger
2. Map form fields to database columns
3. Keep HubSpot sync as is

---

### Option 2: Direct Supabase + n8n Parallel
**Route:** Form → [Supabase + n8n webhook]

**Advantages:**
- Faster database writes
- Less dependency on n8n
- Backup if webhook fails

**Disadvantages:**
- Need to update frontend code
- Two API calls from frontend

---

### Option 3: Backend API Layer (Most Robust)
**Route:** Form → Backend API → [Supabase + n8n + HubSpot]

**Advantages:**
- Full control over data flow
- Can add validation, authentication
- Can handle failures gracefully
- Single source of truth

---

## 🚀 **RECOMMENDED IMPLEMENTATION: Option 1 (n8n)**

### Step 1: Get Supabase Credentials

```bash
# In Supabase Dashboard:
# 1. Go to Project Settings → API
# 2. Copy these values:

Project URL: https://your-project.supabase.co
anon/public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (keep secret!)
```

### Step 2: Add Supabase Node to n8n Workflow

```yaml
# In n8n workflow editor:

1. Click "Add Node" after your webhook trigger
2. Search for "Supabase"
3. Configure credentials:
   - Host: https://your-project.supabase.co
   - Service Role Key: [paste your service_role key]

4. Configure the node:
   - Operation: Insert
   - Table: contacts
   - Map fields:
     * first_name → {{ $json.firstName }}
     * last_name → {{ $json.lastName }}
     * email → {{ $json.email }}
     * phone → {{ $json.phone }}
     * company_name → {{ $json.company }}
     * company_size → {{ $json.companySize }}
     * message → {{ $json.message }}
     * status: "lead" (default)
     * source: "website" (default)
```

### Step 3: Handle Duplicates

```yaml
# Add error handling node:

1. Add "IF" node after Supabase
2. Condition: {{ $node["Supabase"].json.error }} exists
3. If error exists:
   - Check if email already exists
   - Update existing contact instead of creating new
   - Or log error and continue to HubSpot
```

---

## 💻 **ALTERNATIVE: Backend API (Python/FastAPI)**

If you want a backend API layer, here's production-ready code:

### Update backend/requirements.txt:

```txt
fastapi==0.104.1
uvicorn==0.24.0
supabase==2.0.3
python-dotenv==1.0.0
pydantic==2.5.0
httpx==0.25.2
```

### Create backend/.env:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key_here
N8N_WEBHOOK_URL=https://aurumtechnologyltd.app.n8n.cloud/webhook/ab77526e-e5fa-475d-ae34-2d3a88863e19
```

### Update backend/server.py:

```python
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from supabase import create_client, Client
import httpx
import os
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

app = FastAPI(title="Aurum Automation API")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_KEY")
)

# Request model
class ContactFormData(BaseModel):
    firstName: str
    lastName: str
    email: EmailStr
    phone: str | None = None
    company: str | None = None
    companySize: str | None = None
    message: str

# Response model
class ContactResponse(BaseModel):
    success: bool
    message: str
    contact_id: str | None = None

@app.get("/")
async def root():
    return {"status": "ok", "service": "Aurum Automation API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.post("/api/contact", response_model=ContactResponse)
async def submit_contact_form(data: ContactFormData):
    """
    Submit contact form data to Supabase and forward to n8n webhook
    """
    try:
        # 1. Save to Supabase
        contact_data = {
            "first_name": data.firstName,
            "last_name": data.lastName,
            "email": data.email,
            "phone": data.phone,
            "company_name": data.company,
            "company_size": data.companySize,
            "message": data.message,
            "status": "lead",
            "source": "website"
        }
        
        # Check if contact already exists
        existing = supabase.table("contacts").select("id").eq("email", data.email).execute()
        
        if existing.data:
            # Update existing contact
            result = supabase.table("contacts").update(contact_data).eq("email", data.email).execute()
            contact_id = existing.data[0]["id"]
            action = "updated"
        else:
            # Insert new contact
            result = supabase.table("contacts").insert(contact_data).execute()
            contact_id = result.data[0]["id"] if result.data else None
            action = "created"
        
        # 2. Forward to n8n webhook (for HubSpot sync)
        n8n_webhook_url = os.getenv("N8N_WEBHOOK_URL")
        async with httpx.AsyncClient() as client:
            webhook_response = await client.post(
                n8n_webhook_url,
                json=data.dict(),
                timeout=10.0
            )
            webhook_response.raise_for_status()
        
        return ContactResponse(
            success=True,
            message=f"Contact {action} successfully and synced to CRM",
            contact_id=contact_id
        )
        
    except httpx.HTTPError as e:
        # Supabase saved but webhook failed
        print(f"Webhook error: {str(e)}")
        return ContactResponse(
            success=True,
            message="Contact saved but CRM sync pending",
            contact_id=contact_id
        )
        
    except Exception as e:
        print(f"Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process contact form: {str(e)}"
        )

@app.get("/api/contacts")
async def get_contacts(
    status: str | None = None,
    limit: int = 50,
    offset: int = 0
):
    """
    Retrieve contacts from database
    """
    try:
        query = supabase.table("contacts").select("*")
        
        if status:
            query = query.eq("status", status)
        
        result = query.order("created_at", desc=True).range(offset, offset + limit - 1).execute()
        
        return {
            "success": True,
            "count": len(result.data),
            "data": result.data
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve contacts: {str(e)}"
        )

@app.get("/api/stats")
async def get_stats():
    """
    Get dashboard statistics
    """
    try:
        # Get contact counts by status
        contacts = supabase.table("contacts").select("status").execute()
        
        status_counts = {}
        for contact in contacts.data:
            status = contact["status"]
            status_counts[status] = status_counts.get(status, 0) + 1
        
        # Get MRR from view
        mrr = supabase.table("monthly_recurring_revenue").select("*").execute()
        
        return {
            "success": True,
            "contacts_by_status": status_counts,
            "total_contacts": len(contacts.data),
            "mrr": mrr.data[0] if mrr.data else None
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve stats: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Update Frontend to Use Backend API:

```javascript
// In frontend/src/pages/Home.jsx
// Replace the handleSubmit function:

const handleSubmit = async (e) => {
  e.preventDefault();
  
  // Validate form
  const errors = validateForm();
  if (Object.keys(errors).length > 0) {
    setFormErrors(errors);
    return;
  }
  
  setIsSubmitting(true);
  
  try {
    // Send to your backend API instead of directly to n8n
    await axios.post('http://localhost:8000/api/contact', formData);
    
    setFormSubmitted(true);
    setTimeout(() => {
      setFormSubmitted(false);
      setFormData({ 
        firstName: '', 
        lastName: '', 
        email: '', 
        phone: '', 
        company: '', 
        companySize: '', 
        message: '' 
      });
      setFormErrors({});
    }, 3000);
  } catch (error) {
    console.error('Form submission failed:', error);
    alert('Failed to submit form. Please try again or contact us directly.');
  } finally {
    setIsSubmitting(false);
  }
};
```

---

## 🔐 **SECURITY BEST PRACTICES**

### 1. Never Expose Service Role Key
- ✅ Use in backend only (server.py or n8n)
- ❌ Never use in frontend code
- ✅ Store in environment variables

### 2. Enable RLS (Row Level Security)
```sql
-- Already done in setup script, but verify:
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

-- Allow public inserts (for contact form)
CREATE POLICY "Allow public insert" ON contacts
  FOR INSERT WITH CHECK (true);

-- Restrict reads to authenticated users only
CREATE POLICY "Authenticated read only" ON contacts
  FOR SELECT USING (auth.role() = 'authenticated');
```

### 3. Rate Limiting
Add rate limiting to prevent spam:

```python
# Add to backend/server.py
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.post("/api/contact")
@limiter.limit("5/minute")  # Max 5 submissions per minute
async def submit_contact_form(request: Request, data: ContactFormData):
    # ... existing code
```

---

## 🧪 **TESTING**

### Test Supabase Connection:

```bash
# Install Supabase CLI
npm install -g supabase

# Test connection
supabase db ping --project-ref your-project-ref
```

### Test Backend API:

```bash
# Start backend
cd backend
python server.py

# Test health endpoint
curl http://localhost:8000/health

# Test contact submission
curl -X POST http://localhost:8000/api/contact \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Test",
    "lastName": "User",
    "email": "test@example.com",
    "phone": "868-123-4567",
    "company": "Test Company",
    "companySize": "1-10",
    "message": "This is a test submission"
  }'
```

---

## 📊 **MONITORING**

### Supabase Dashboard
- Monitor API requests
- View table activity
- Check RLS policies
- Review logs

### n8n Workflow
- Check execution history
- Monitor error rates
- View data transformations

---

## 🚀 **DEPLOYMENT**

### Backend Deployment Options:
1. **Railway** (Easiest)
2. **Heroku**
3. **DigitalOcean App Platform**
4. **AWS Lambda** (Serverless)
5. **Vercel** (Serverless Functions)

### Environment Variables to Set:
```env
SUPABASE_URL=your_url
SUPABASE_SERVICE_KEY=your_key
N8N_WEBHOOK_URL=your_webhook_url
ALLOWED_ORIGINS=https://yoursite.com
```

---

## ✅ **RECOMMENDED SETUP**

For your use case, I recommend:
1. ✅ Keep n8n webhook as primary endpoint
2. ✅ Add Supabase node in n8n workflow
3. ✅ This gives you: Form → n8n → [Supabase + HubSpot]
4. ✅ Later, add backend API when you need custom logic

---

Would you like me to help you implement any of these options?
