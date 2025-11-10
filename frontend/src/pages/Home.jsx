import React, { useState } from 'react';
import { Button } from '../components/ui/button';
import { Card } from '../components/ui/card';
import { Input } from '../components/ui/input';
import { Textarea } from '../components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../components/ui/select';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '../components/ui/accordion';
import { MessageSquare, Users, Mail, Phone, Share2, CheckCircle2, Star, Clock, Shield, Award, Menu, X, Lock } from 'lucide-react';
import { mockData } from '../mockData';
import axios from 'axios';

const Home = () => {
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: '',
    companySize: '',
    message: '',
    website: '' // Honeypot field - bots will fill this
  });
  const [formErrors, setFormErrors] = useState({});
  const [formSubmitted, setFormSubmitted] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
    // Clear error when user starts typing
    if (formErrors[name]) {
      setFormErrors({ ...formErrors, [name]: '' });
    }
  };

  const handleSelectChange = (value) => {
    setFormData({ ...formData, companySize: value });
  };

  const validateForm = () => {
    const errors = {};
    
    if (!formData.firstName.trim()) {
      errors.firstName = 'First name is required';
    }
    
    if (!formData.lastName.trim()) {
      errors.lastName = 'Last name is required';
    }
    
    if (!formData.email.trim()) {
      errors.email = 'Email is required';
    } else if (!/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i.test(formData.email)) {
      errors.email = 'Please enter a valid email address';
    }
    
    if (!formData.message.trim()) {
      errors.message = 'Please tell us about your automation needs';
    } else if (formData.message.trim().length < 10) {
      errors.message = 'Please provide more details (at least 10 characters)';
    }
    
    return errors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Bot detection: Check honeypot field
    if (formData.website && formData.website.trim() !== '') {
      // Bot detected - silently reject without showing error
      console.log('Bot submission blocked');
      return;
    }
    
    // Validate form
    const errors = validateForm();
    if (Object.keys(errors).length > 0) {
      setFormErrors(errors);
      return;
    }
    
    setIsSubmitting(true);
    
    try {
      await axios.post('https://aurumtechnologyltd.app.n8n.cloud/webhook/ab77526e-e5fa-475d-ae34-2d3a88863e19', formData);
      setFormSubmitted(true);
      setTimeout(() => {
        setFormSubmitted(false);
        setFormData({ firstName: '', lastName: '', email: '', phone: '', company: '', companySize: '', message: '', website: '' });
        setFormErrors({});
      }, 3000);
    } catch (error) {
      console.error('Form submission failed:', error);
      alert('Failed to submit form. Please try again or contact us directly.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const scrollToContact = () => {
    document.getElementById('contact')?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <div className="landing-page">
      {/* Header */}
      <header className="header">
        <div className="header-container">
          <div className="logo-container">
            <img 
              src="https://customer-assets.emergentagent.com/job_trini-ai-agency/artifacts/akx3it2v_Aurum%20Technology%20Limited%20Logo.png" 
              alt="Aurum Automation" 
              className="logo"
            />
          </div>
          <nav className="nav">
            <a href="#services" className="nav-link">Services</a>
            <a href="#pricing" className="nav-link">Pricing</a>
            <a href="#tech" className="nav-link">Technology</a>
            <a href="#contact" className="nav-link">Contact</a>
          </nav>
          <button 
            className="mobile-menu-button" 
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle menu"
          >
            {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
        
        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="mobile-menu">
            <a href="#services" className="mobile-nav-link" onClick={() => setMobileMenuOpen(false)}>Services</a>
            <a href="#pricing" className="mobile-nav-link" onClick={() => setMobileMenuOpen(false)}>Pricing</a>
            <a href="#tech" className="mobile-nav-link" onClick={() => setMobileMenuOpen(false)}>Technology</a>
            <a href="#contact" className="mobile-nav-link" onClick={() => setMobileMenuOpen(false)}>Contact</a>
          </div>
        )}
      </header>

      {/* Hero Section */}
      <section className="hero">
        <div className="hero-container">
          <div className="hero-content">
            <h1 className="hero-title">
              {mockData.hero.title}
            </h1>
            <p className="hero-tagline">{mockData.hero.tagline}</p>
            <p className="hero-description">
              {mockData.hero.description}
            </p>
            <div className="hero-buttons">
              <Button onClick={scrollToContact} className="btn-primary">
                Get My Free Demo
              </Button>
              <Button onClick={() => window.location.href = '#services'} className="btn-secondary">
                See How It Works
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Services Section */}
      <section id="services" className="section services-section">
        <div className="section-container">
          <h2 className="section-title">Core Services</h2>
          <p className="section-subtitle">
            World-class automation solutions designed for Caribbean businesses
          </p>
          <div className="services-grid">
            {mockData.services.map((service, index) => {
              const icons = {
                'MessageSquare': MessageSquare,
                'Users': Users,
                'Mail': Mail,
                'Phone': Phone,
                'Share2': Share2
              };
              const Icon = icons[service.icon];
              return (
                <Card key={index} className="service-card">
                  <div className="service-icon">
                    <Icon className="icon" />
                  </div>
                  <h3 className="service-title">{service.title}</h3>
                  <p className="service-description">{service.description}</p>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="section pricing-section">
        <div className="section-container">
          <h2 className="section-title">Transparent Pricing</h2>
          <p className="section-subtitle">
            No long-term contracts. Cancel anytime with 30 days' notice.
          </p>
          
          <div className="pricing-overview">
            <div className="pricing-grid">
              {mockData.pricing.overview.map((item, index) => (
                <Card key={index} className="pricing-card">
                  <div className="pricing-header">
                    <h3 className="pricing-title">{item.title}</h3>
                  </div>
                  <div className="pricing-body">
                    <div className="pricing-amount">{item.range}</div>
                    <div className="pricing-usd">{item.usd}</div>
                    <p className="pricing-note">{item.note}</p>
                  </div>
                </Card>
              ))}
            </div>
          </div>

          <div className="pricing-example">
            <Card className="example-card">
              <h3 className="example-title">Example Package</h3>
              <p className="example-description">{mockData.pricing.example}</p>
            </Card>
          </div>

          <div className="pricing-note-box">
            <p className="note-text">
              <strong>All pricing varies</strong> depending on client requirements and project scope.
            </p>
          </div>
        </div>
      </section>

      {/* Tech Stack Section */}
      <section id="tech" className="section tech-section">
        <div className="section-container">
          <h2 className="section-title">Our Technology Stack</h2>
          <p className="section-subtitle">
            Enterprise-grade platforms delivering exceptional results
          </p>
          <div className="tech-grid">
            {mockData.techStack.map((tech, index) => (
              <Card key={index} className="tech-card">
                <div className="tech-name">{tech}</div>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* What Sets Us Apart */}
      <section className="section apart-section">
        <div className="section-container">
          <h2 className="section-title">What Sets Us Apart</h2>
          <div className="apart-grid">
            {mockData.differences.map((diff, index) => {
              const icons = {
                'Star': Star,
                'CheckCircle2': CheckCircle2,
                'Clock': Clock,
                'Shield': Shield,
                'Award': Award
              };
              const Icon = icons[diff.icon];
              return (
                <Card key={index} className="apart-card">
                  <div className="apart-icon">
                    <Icon className="icon" />
                  </div>
                  <h3 className="apart-title">{diff.title}</h3>
                  <p className="apart-description">{diff.description}</p>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <section id="faq" className="section faq-section">
        <div className="section-container">
          <h2 className="section-title">Frequently Asked Questions</h2>
          <p className="section-subtitle">
            Everything you need to know about our automation services
          </p>
          
          <div className="faq-container">
            <Accordion type="single" collapsible className="faq-accordion">
              {mockData.faqs.map((faq, index) => (
                <AccordionItem key={index} value={`item-${index}`} className="faq-item">
                  <AccordionTrigger className="faq-question">{faq.question}</AccordionTrigger>
                  <AccordionContent className="faq-answer">{faq.answer}</AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section id="contact" className="section contact-section">
        <div className="section-container">
          <h2 className="section-title">Get In Touch</h2>
          <p className="section-subtitle">
            Ready to transform your business with AI automation?
          </p>
          
          <div className="contact-content">
            <div className="contact-info">
              <Card className="info-card">
                <h3 className="info-title">Contact Information</h3>
                <div className="info-items">
                  <div className="info-item">
                    <Mail className="info-icon" />
                    <div>
                      <div className="info-label">Email</div>
                      <a href={`mailto:${mockData.contact.email}`} className="info-value">
                        {mockData.contact.email}
                      </a>
                    </div>
                  </div>
                  <div className="info-item">
                    <Phone className="info-icon" />
                    <div>
                      <div className="info-label">Phone</div>
                      <a href={`tel:${mockData.contact.phone}`} className="info-value">
                        {mockData.contact.phone}
                      </a>
                    </div>
                  </div>
                  <div className="info-item">
                    <Share2 className="info-icon" />
                    <div>
                      <div className="info-label">Website</div>
                      <a href={mockData.contact.website} target="_blank" rel="noopener noreferrer" className="info-value">
                        {mockData.contact.website}
                      </a>
                    </div>
                  </div>
                </div>
              </Card>
            </div>

            <div className="contact-form-wrapper">
              <Card className="form-card">
                <form onSubmit={handleSubmit} className="contact-form">
                  <div className="form-group">
                    <label htmlFor="firstName" className="form-label">First Name *</label>
                    <Input
                      id="firstName"
                      name="firstName"
                      type="text"
                      required
                      value={formData.firstName}
                      onChange={handleInputChange}
                      className={`form-input ${formErrors.firstName ? 'error' : ''}`}
                      placeholder="John"
                    />
                    {formErrors.firstName && <span className="error-message">{formErrors.firstName}</span>}
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="lastName" className="form-label">Last Name *</label>
                    <Input
                      id="lastName"
                      name="lastName"
                      type="text"
                      required
                      value={formData.lastName}
                      onChange={handleInputChange}
                      className={`form-input ${formErrors.lastName ? 'error' : ''}`}
                      placeholder="Smith"
                    />
                    {formErrors.lastName && <span className="error-message">{formErrors.lastName}</span>}
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="email" className="form-label">Email *</label>
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      required
                      value={formData.email}
                      onChange={handleInputChange}
                      className={`form-input ${formErrors.email ? 'error' : ''}`}
                      placeholder="your.email@company.com"
                    />
                    {formErrors.email && <span className="error-message">{formErrors.email}</span>}
                  </div>

                  {/* Honeypot field - hidden from humans, filled by bots */}
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

                  <div className="form-group">
                    <label htmlFor="phone" className="form-label">Phone Number</label>
                    <Input
                      id="phone"
                      name="phone"
                      type="tel"
                      value={formData.phone}
                      onChange={handleInputChange}
                      className="form-input"
                      placeholder="+1 (868) 123-4567"
                    />
                  </div>

                  <div className="form-group">
                    <label htmlFor="company" className="form-label">Company Name</label>
                    <Input
                      id="company"
                      name="company"
                      type="text"
                      value={formData.company}
                      onChange={handleInputChange}
                      className="form-input"
                      placeholder="Your company name"
                    />
                  </div>

                  <div className="form-group">
                    <label htmlFor="companySize" className="form-label">Company Size</label>
                    <Select onValueChange={handleSelectChange} value={formData.companySize}>
                      <SelectTrigger className="form-input">
                        <SelectValue placeholder="Select company size" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="1-10">1-10 employees</SelectItem>
                        <SelectItem value="11-50">11-50 employees</SelectItem>
                        <SelectItem value="51-200">51-200 employees</SelectItem>
                        <SelectItem value="201-500">201-500 employees</SelectItem>
                        <SelectItem value="501-1000">501-1000 employees</SelectItem>
                        <SelectItem value="1000+">1000+ employees</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="form-group">
                    <label htmlFor="message" className="form-label">Message *</label>
                    <Textarea
                      id="message"
                      name="message"
                      required
                      value={formData.message}
                      onChange={handleInputChange}
                      className={`form-textarea ${formErrors.message ? 'error' : ''}`}
                      placeholder="Tell us about your automation needs..."
                      rows={4}
                    />
                    {formErrors.message && <span className="error-message">{formErrors.message}</span>}
                  </div>

                  <div className="privacy-notice">
                    <Lock size={16} className="privacy-icon" />
                    <span>Your information is secure. We never share your data and respect your privacy.</span>
                  </div>

                  {formSubmitted && (
                    <div className="success-message">
                      <CheckCircle2 className="success-icon" />
                      <span>Thank you! We'll get back to you within 24 hours.</span>
                    </div>
                  )}

                  <Button type="submit" className="btn-submit" disabled={isSubmitting}>
                    {isSubmitting ? 'Sending Your Message...' : 'Get My Free Consultation'}
                  </Button>
                </form>
              </Card>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer">
        <div className="footer-container">
          <div className="footer-content">
            <div className="footer-logo">
              <img 
                src="https://customer-assets.emergentagent.com/job_trini-ai-agency/artifacts/akx3it2v_Aurum%20Technology%20Limited%20Logo.png" 
                alt="Aurum Automation" 
                className="logo"
              />
            </div>
            <p className="footer-tagline">
              Bringing world-class AI automation to the Caribbean, one business at a time.
            </p>
          </div>
          <div className="footer-bottom">
            <p className="footer-copyright">
              © {new Date().getFullYear()} Aurum Automation. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Home;