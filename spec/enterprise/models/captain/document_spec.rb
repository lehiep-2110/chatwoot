require 'rails_helper'

RSpec.describe Captain::Document, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe 'URL normalization' do
    it 'removes a trailing slash before validation' do
      document = create(:captain_document,
                        assistant: assistant,
                        account: account,
                        external_link: 'https://example.com/path/')

      expect(document.external_link).to eq('https://example.com/path')
    end
  end

  describe '#customer_visible_source_url' do
    let(:document) do
      build(:captain_document, assistant: assistant, account: account, external_link: 'https://example.com/runbooks')
    end

    it 'returns URLs that resolve only to public addresses' do
      allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])

      expect(document.customer_visible_source_url).to eq('https://example.com/runbooks')
    end

    it 'rejects URLs that resolve to private, loopback, or link-local addresses' do
      ['10.0.0.5', '127.0.0.1', '169.254.1.1', 'fc00::1', 'fe80::1'].each do |address|
        allow(Resolv).to receive(:getaddresses).with('example.com').and_return([address])

        expect(document.customer_visible_source_url).to be_nil
      end
    end

    it 'rejects URLs with mixed public and private addresses' do
      allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34', '10.0.0.5'])

      expect(document.customer_visible_source_url).to be_nil
    end

    it 'rejects URLs with unresolved hosts' do
      allow(Resolv).to receive(:getaddresses).with('example.com').and_return([])

      expect(document.customer_visible_source_url).to be_nil
    end
  end

  describe 'PDF support' do
    let(:pdf_document) do
      doc = build(:captain_document, assistant: assistant, account: account)
      doc.pdf_file.attach(
        io: StringIO.new('PDF content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      doc
    end

    describe 'validations' do
      it 'allows PDF file without external link' do
        pdf_document.external_link = nil
        expect(pdf_document).to be_valid
      end

      it 'validates PDF file size' do
        doc = build(:captain_document, assistant: assistant, account: account)
        doc.pdf_file.attach(
          io: StringIO.new('x' * 11.megabytes),
          filename: 'large.pdf',
          content_type: 'application/pdf'
        )
        doc.external_link = nil
        expect(doc).not_to be_valid
        expect(doc.errors[:pdf_file]).to include(I18n.t('captain.documents.pdf_size_error'))
      end
    end

    describe '#pdf_document?' do
      it 'returns true for attached PDF' do
        expect(pdf_document.pdf_document?).to be true
      end

      it 'returns true for .pdf external links' do
        doc = build(:captain_document, external_link: 'https://example.com/document.pdf')
        expect(doc.pdf_document?).to be true
      end

      it 'returns true for PDF:-prefixed external links even when the blob is missing' do
        doc = build(:captain_document, external_link: 'PDF: report_20250101120000')
        expect(doc.pdf_document?).to be true
      end

      it 'returns false for non-PDF documents' do
        doc = build(:captain_document, external_link: 'https://example.com')
        expect(doc.pdf_document?).to be false
      end
    end

    describe '#display_url' do
      it 'returns Rails blob URL for attached PDFs' do
        pdf_document.save!
        # The display_url method calls rails_blob_url which returns a URL containing 'rails/active_storage'
        url = pdf_document.display_url
        expect(url).to be_present
      end

      it 'returns external_link for web documents' do
        doc = create(:captain_document, external_link: 'https://example.com')
        expect(doc.display_url).to eq('https://example.com')
      end
    end

    describe '#store_openai_file_id' do
      it 'stores the file ID in metadata' do
        pdf_document.save!
        pdf_document.store_openai_file_id('file-abc123')

        expect(pdf_document.reload.openai_file_id).to eq('file-abc123')
      end
    end

    describe 'automatic external_link generation' do
      it 'generates unique external_link for PDFs' do
        pdf_document.external_link = nil
        pdf_document.save!

        expect(pdf_document.external_link).to start_with('PDF: test_')
      end
    end
  end

  describe 'Markdown support' do
    let(:markdown_content) { "# Refund policy\n\nRefunds are processed within five business days." }
    let(:markdown_document) do
      build(
        :captain_document,
        assistant: assistant,
        account: account,
        external_link: nil,
        name: 'playground-knowledge.md',
        markdown_content: markdown_content
      )
    end

    it 'stores the uploaded file as an available document' do
      markdown_document.save!

      expect(markdown_document).to be_available
      expect(markdown_document).to be_markdown_document
      expect(markdown_document).not_to be_syncable
      expect(markdown_document.content).to eq(markdown_content)
      expect(markdown_document.external_link).to start_with('MARKDOWN: playground-knowledge_')
    end

    it 'attaches the content as a Markdown file' do
      markdown_document.save!

      expect(markdown_document.markdown_file.filename.to_s).to eq('playground-knowledge.md')
      expect(markdown_document.markdown_file.content_type).to eq('text/markdown')
      expect(markdown_document.markdown_file.download).to eq(markdown_content)
    end

    it 'uses the Markdown filename when a name is not provided' do
      markdown_document.name = nil
      markdown_document.save!

      expect(markdown_document.name).to eq('playground-knowledge.md')
    end

    it 'rejects Markdown content longer than the playground limit' do
      markdown_document.markdown_content = 'a' * 10_001

      expect(markdown_document).not_to be_valid
      expect(markdown_document.errors[:markdown_file]).to include(I18n.t('captain.documents.markdown_size_error'))
    end

    it 'rejects non-Markdown attachments' do
      invalid_document = build(
        :captain_document,
        assistant: assistant,
        account: account,
        external_link: nil,
        content: 'not markdown',
        status: :available
      )
      invalid_document.markdown_file.attach(
        io: StringIO.new('not markdown'),
        filename: 'knowledge.txt',
        content_type: 'text/plain'
      )

      expect(invalid_document).not_to be_valid
      expect(invalid_document.errors[:markdown_file]).to include(I18n.t('captain.documents.markdown_format_error'))
    end

    it 'rejects a document with both PDF and Markdown attachments' do
      markdown_document.pdf_file.attach(
        io: StringIO.new('PDF content'),
        filename: 'refund-policy.pdf',
        content_type: 'application/pdf'
      )

      expect(markdown_document).not_to be_valid
      expect(markdown_document.errors[:base]).to include(I18n.t('captain.documents.multiple_files_error'))
    end
  end

  it 'keeps document content updates without scheduling retired AI processing' do
    document = create(:captain_document, account: account, assistant: assistant, status: :available)

    expect do
      document.update!(content: 'Historical content update')
    end.not_to have_enqueued_job(Captain::Documents::ResponseBuilderJob)

    expect(document.reload.content).to eq('Historical content update')
  end
end
