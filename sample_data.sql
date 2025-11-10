-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================
-- Run this AFTER running supabase_setup.sql
-- This populates your database with realistic test data
-- =====================================================

-- Insert sample companies
INSERT INTO companies (company_name, industry, company_size, website, city, country, status, monthly_recurring, total_revenue, contract_start_date) VALUES
('Caribbean Medical Clinic', 'Healthcare', '11-50', 'https://caribmedclinic.com', 'Port of Spain', 'Trinidad and Tobago', 'active', 3500.00, 15000.00, '2024-01-15'),
('Trinidad Legal Associates', 'Legal', '1-10', 'https://trinidadlegal.com', 'San Fernando', 'Trinidad and Tobago', 'active', 2500.00, 12000.00, '2024-02-01'),
('Island Retail Group', 'Retail', '51-200', 'https://islandretail.com', 'Bridgetown', 'Barbados', 'prospect', 0, 0, NULL),
('Tech Startup TT', 'Technology', '11-50', 'https://techstartuptt.com', 'Port of Spain', 'Trinidad and Tobago', 'active', 4000.00, 18000.00, '2023-11-20');

-- Insert sample contacts
INSERT INTO contacts (first_name, last_name, email, phone, company_name, company_size, message, status, source, company_id) VALUES
('Dr. Sarah', 'Mohammed', 'sarah.mohammed@caribmedclinic.com', '(868) 623-4567', 'Caribbean Medical Clinic', '11-50', 'Looking for AI chatbot for after-hours patient inquiries', 'converted', 'website', (SELECT id FROM companies WHERE company_name = 'Caribbean Medical Clinic')),
('Michael', 'Rodriguez', 'michael@trinidadlegal.com', '(868) 652-8901', 'Trinidad Legal Associates', '1-10', 'Need appointment scheduling automation', 'converted', 'referral', (SELECT id FROM companies WHERE company_name = 'Trinidad Legal Associates')),
('Jennifer', 'Chen', 'jchen@islandretail.com', '(246) 234-5678', 'Island Retail Group', '51-200', 'Interested in lead generation and WhatsApp automation', 'qualified', 'website', (SELECT id FROM companies WHERE company_name = 'Island Retail Group')),
('Marcus', 'Williams', 'marcus.w@techstartuptt.com', '(868) 789-0123', 'Tech Startup TT', '11-50', 'Looking for email marketing automation and CRM integration', 'converted', 'linkedin', (SELECT id FROM companies WHERE company_name = 'Tech Startup TT')),
('Amanda', 'Singh', 'amanda.singh@example.com', '(868) 555-0101', 'Singh Accounting Services', '1-10', 'Need help automating client onboarding process', 'contacted', 'website', NULL);

-- Update companies with primary contacts
UPDATE companies SET primary_contact_id = (SELECT id FROM contacts WHERE email = 'sarah.mohammed@caribmedclinic.com') WHERE company_name = 'Caribbean Medical Clinic';
UPDATE companies SET primary_contact_id = (SELECT id FROM contacts WHERE email = 'michael@trinidadlegal.com') WHERE company_name = 'Trinidad Legal Associates';
UPDATE companies SET primary_contact_id = (SELECT id FROM contacts WHERE email = 'jchen@islandretail.com') WHERE company_name = 'Island Retail Group';
UPDATE companies SET primary_contact_id = (SELECT id FROM contacts WHERE email = 'marcus.w@techstartuptt.com') WHERE company_name = 'Tech Startup TT';

-- Insert sample projects
INSERT INTO projects (company_id, project_name, project_type, description, status, setup_fee, monthly_fee, tool_costs, start_date, go_live_date, priority) VALUES
(
  (SELECT id FROM companies WHERE company_name = 'Caribbean Medical Clinic'),
  'Medical Clinic AI Chatbot',
  'chatbot',
  '24/7 chatbot for patient inquiries, appointment info, and common medical questions',
  'live',
  12000.00,
  3000.00,
  500.00,
  '2024-01-20',
  '2024-02-15',
  'high'
),
(
  (SELECT id FROM companies WHERE company_name = 'Trinidad Legal Associates'),
  'Legal Practice Automation Suite',
  'chatbot',
  'Client intake chatbot + automated appointment scheduling',
  'live',
  10000.00,
  2500.00,
  400.00,
  '2024-02-05',
  '2024-03-01',
  'medium'
),
(
  (SELECT id FROM companies WHERE company_name = 'Tech Startup TT'),
  'Email Marketing + HubSpot Integration',
  'email_automation',
  'Automated email campaigns with HubSpot CRM integration',
  'live',
  8000.00,
  1800.00,
  600.00,
  '2023-12-01',
  '2024-01-10',
  'medium'
),
(
  (SELECT id FROM companies WHERE company_name = 'Island Retail Group'),
  'Multi-Channel Lead Generation',
  'lead_gen',
  'WhatsApp business automation + lead capture system',
  'in_progress',
  15000.00,
  4500.00,
  800.00,
  '2024-03-01',
  NULL,
  'high'
);

-- Link projects to services
INSERT INTO project_services (project_id, service_id) VALUES
((SELECT id FROM projects WHERE project_name = 'Medical Clinic AI Chatbot'), (SELECT id FROM services WHERE service_name = 'AI Chatbot & Virtual Assistant')),
((SELECT id FROM projects WHERE project_name = 'Legal Practice Automation Suite'), (SELECT id FROM services WHERE service_name = 'AI Chatbot & Virtual Assistant')),
((SELECT id FROM projects WHERE project_name = 'Legal Practice Automation Suite'), (SELECT id FROM services WHERE service_name = 'AI Receptionist Automation')),
((SELECT id FROM projects WHERE project_name = 'Email Marketing + HubSpot Integration'), (SELECT id FROM services WHERE service_name = 'Email Marketing Automation')),
((SELECT id FROM projects WHERE project_name = 'Email Marketing + HubSpot Integration'), (SELECT id FROM services WHERE service_name = 'Workflow Integration')),
((SELECT id FROM projects WHERE project_name = 'Multi-Channel Lead Generation'), (SELECT id FROM services WHERE service_name = 'Lead Generation Automation'));

-- Insert sample invoices
INSERT INTO invoices (invoice_number, company_id, project_id, invoice_type, amount, amount_usd, status, issue_date, due_date, paid_date) VALUES
(
  'INV-2024-001',
  (SELECT id FROM companies WHERE company_name = 'Caribbean Medical Clinic'),
  (SELECT id FROM projects WHERE project_name = 'Medical Clinic AI Chatbot'),
  'setup',
  12000.00,
  1800.00,
  'paid',
  '2024-01-20',
  '2024-02-05',
  '2024-02-03'
),
(
  'INV-2024-002',
  (SELECT id FROM companies WHERE company_name = 'Caribbean Medical Clinic'),
  (SELECT id FROM projects WHERE project_name = 'Medical Clinic AI Chatbot'),
  'monthly',
  3000.00,
  450.00,
  'paid',
  '2024-03-01',
  '2024-03-15',
  '2024-03-10'
),
(
  'INV-2024-003',
  (SELECT id FROM companies WHERE company_name = 'Trinidad Legal Associates'),
  (SELECT id FROM projects WHERE project_name = 'Legal Practice Automation Suite'),
  'setup',
  10000.00,
  1500.00,
  'paid',
  '2024-02-05',
  '2024-02-20',
  '2024-02-18'
),
(
  'INV-2024-004',
  (SELECT id FROM companies WHERE company_name = 'Island Retail Group'),
  (SELECT id FROM projects WHERE project_name = 'Multi-Channel Lead Generation'),
  'setup',
  15000.00,
  2250.00,
  'sent',
  '2024-03-01',
  '2024-03-15',
  NULL
);

-- Insert sample meetings
INSERT INTO meetings (contact_id, company_id, meeting_type, title, description, scheduled_at, duration_minutes, status, outcome) VALUES
(
  (SELECT id FROM contacts WHERE email = 'jchen@islandretail.com'),
  (SELECT id FROM companies WHERE company_name = 'Island Retail Group'),
  'discovery',
  'Initial Discovery Call - Island Retail',
  'Discuss lead generation needs and WhatsApp automation opportunities',
  '2024-02-15 10:00:00+00',
  45,
  'completed',
  'Client interested in full lead gen suite. Moving to demo phase.'
),
(
  (SELECT id FROM contacts WHERE email = 'amanda.singh@example.com'),
  NULL,
  'discovery',
  'Discovery Call - Singh Accounting',
  'Explore automation opportunities for accounting practice',
  '2024-03-20 14:00:00+00',
  30,
  'scheduled',
  NULL
);

-- Insert sample integrations
INSERT INTO integrations (project_id, tool_name, tool_category, status, monthly_cost, notes) VALUES
(
  (SELECT id FROM projects WHERE project_name = 'Medical Clinic AI Chatbot'),
  'Botpress',
  'chatbot',
  'active',
  300.00,
  'Pro plan for advanced NLP features'
),
(
  (SELECT id FROM projects WHERE project_name = 'Medical Clinic AI Chatbot'),
  'Calendly',
  'scheduling',
  'active',
  200.00,
  'Professional plan for team scheduling'
),
(
  (SELECT id FROM projects WHERE project_name = 'Email Marketing + HubSpot Integration'),
  'HubSpot',
  'crm',
  'active',
  500.00,
  'Starter CRM plan'
),
(
  (SELECT id FROM projects WHERE project_name = 'Email Marketing + HubSpot Integration'),
  'Make.com',
  'automation',
  'active',
  100.00,
  'Core plan for workflow automation'
);

-- Insert sample support tickets
INSERT INTO support_tickets (ticket_number, company_id, project_id, contact_id, subject, description, priority, status, category) VALUES
(
  'TKT-2024-001',
  (SELECT id FROM companies WHERE company_name = 'Caribbean Medical Clinic'),
  (SELECT id FROM projects WHERE project_name = 'Medical Clinic AI Chatbot'),
  (SELECT id FROM contacts WHERE email = 'sarah.mohammed@caribmedclinic.com'),
  'Chatbot not recognizing medical abbreviations',
  'The chatbot is having trouble understanding common medical abbreviations like "BP" for blood pressure',
  'medium',
  'resolved',
  'bug'
),
(
  'TKT-2024-002',
  (SELECT id FROM companies WHERE company_name = 'Trinidad Legal Associates'),
  (SELECT id FROM projects WHERE project_name = 'Legal Practice Automation Suite'),
  (SELECT id FROM contacts WHERE email = 'michael@trinidadlegal.com'),
  'Request to add new appointment type',
  'Need to add "Court Appearance" as a new appointment type in the scheduling system',
  'low',
  'open',
  'feature_request'
);

-- Insert sample notes
INSERT INTO notes (note_type, related_id, note_text, is_private) VALUES
(
  'company',
  (SELECT id FROM companies WHERE company_name = 'Caribbean Medical Clinic'),
  'Client very satisfied with chatbot performance. Mentioned potential for referrals to other medical practices.',
  false
),
(
  'project',
  (SELECT id FROM projects WHERE project_name = 'Multi-Channel Lead Generation'),
  'Client requested demo of WhatsApp Business API integration before final approval',
  false
),
(
  'contact',
  (SELECT id FROM contacts WHERE email = 'amanda.singh@example.com'),
  'Follow up in 1 week. Client needs to discuss with business partner first.',
  true
);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these to verify your data was inserted correctly

-- Check companies
SELECT company_name, status, monthly_recurring FROM companies;

-- Check contacts
SELECT first_name, last_name, company_name, status FROM contacts;

-- Check projects with company names
SELECT p.project_name, c.company_name, p.status, p.monthly_fee 
FROM projects p 
JOIN companies c ON p.company_id = c.id;

-- Check MRR view
SELECT * FROM monthly_recurring_revenue;

-- Check active clients
SELECT * FROM active_clients_overview;

-- =====================================================
-- TEST DATA INSERTED SUCCESSFULLY!
-- =====================================================
