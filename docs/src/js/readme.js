import integrationsData from "./config.js";
const urlParams = new URLSearchParams(window.location.search);
const integrationId = urlParams.get('id');
const readmeContentDiv = document.getElementById('readme-content');
const sidebarContentDiv = document.getElementById('sidebar-content');
const mainReadmeArea = document.getElementById('main-readme-area');
const searchToggleButton = document.getElementById('searchToggleButton');
const searchContainer = document.getElementById('searchContainer');
const searchInput = document.getElementById('searchInput');
const loadingBar = document.querySelector('.loading-bar');
const loadingMessage = readmeContentDiv.querySelector('p');

let headingElements = [];
let sidebarLinks = [];

async function fetchMarkdown(url) {
    try {
        const response = await fetch(url);
        if (response.ok) {
            return await response.text();
        } else {
            console.warn(`Failed to fetch markdown from ${url}: Status ${response.status}`);
            return null;
        }
    } catch (error) {
        console.error(`Error during fetch for ${url}:`, error);
        return null;
    }
}

async function fetchReadme() {
    if (loadingBar) loadingBar.classList.add('active');
    if (loadingMessage) loadingMessage.style.display = 'block';
    document.getElementById('main-content').style.display = 'grid';
    document.getElementById('load').style.display = 'none';
    let readmeMarkdown = null;

    if (integrationId) {
        document.title = `${integrationId} - zop.dev`;
    } else {
        document.title = 'Integration - zop.dev';
    }

    if (integrationId === 'contribution') {
        const contributionUrl = 'https://raw.githubusercontent.com/zopdev/helm-charts/main/CONTRIBUTING.md';
        readmeMarkdown = await fetchMarkdown(contributionUrl);
    } else {
        const integrationExists = Object.values(integrationsData.categories).flat().some(integration => integration.id === integrationId);

        if (!integrationId || !integrationExists) {
            document.body.innerHTML = `
                <div style="text-align: center; padding: 20px;">
                    <img decoding="async" width="671" height="671" sizes="calc(min(100vw * 0.8867, 1064px) * 0.6)" srcset="https://framerusercontent.com/images/oG2yEHscd5VhHxwWhQzz7ygGVBU.svg?scale-down-to=512 512w,https://framerusercontent.com/images/oG2yEHscd5VhHxwWhQzz7ygGVBU.svg 761w" src="https://framerusercontent.com/images/oG2yEHscd5VhHxwWhQzz7ygGVBU.svg" alt="" style="display:block;border-radius:inherit;object-position:center;object-fit:cover; margin: 0 auto;">
                    <button onclick="window.location.href='./index.html'" style="margin-top: 20px; padding: 10px 20px; background-color: #0D7997; color: white; border: none; border-radius: 5px; cursor: pointer;">Home Page</button>
                </div>
            `;
            if (loadingBar) loadingBar.classList.remove('active');
            if (loadingMessage) loadingMessage.style.display = 'none';
            return;
        }

        const baseUrl = `https://raw.githubusercontent.com/zopdev/helm-charts/main/charts/${integrationId}/`;
        const readmeUrlsToTry = [`${baseUrl}README.md`, `${baseUrl}Readme.md`];

        readmeMarkdown = await fetchMarkdown(readmeUrlsToTry[0]);

        if (readmeMarkdown === null) {
            readmeMarkdown = await fetchMarkdown(readmeUrlsToTry[1]);
        }
    }

    if (readmeMarkdown !== null) {
        const readmeHtml = marked.parse(readmeMarkdown);
        processAndDisplayReadme(readmeHtml);
    } else {
        document.body.innerHTML = `
            <div style="text-align: center; padding: 20px;">
                <img decoding="async" width="671" height="671" sizes="calc(min(100vw * 0.8867, 1064px) * 0.6)" srcset="https://framerusercontent.com/images/oG2yEHscd5VhHxwWhQzz7ygGVBU.svg?scale-down-to=512 512w,https://framerusercontent.com/images/oG2yEHscd5VhHxwWhQzz7ygGVBU.svg 761w" src="https://framerusercontent.com/images/oG2yEHscd5VhHxwWhQzz7ygGVBU.svg" alt="" style="display:block;border-radius:inherit;object-position:center;object-fit:cover; margin: 0 auto;">
                <button onclick="window.location.href='./index.html'" style="margin-top: 20px; padding: 10px 20px; background-color: #0D7997; color: white; border: none; border-radius: 5px; cursor: pointer;">Home Page</button>
                ${integrationId === 'contribution' ? '<p style="color: #ef4444; margin-top: 15px;">Error loading CONTRIBUTING.md content.</p>' : ''}
            </div>
        `;
    }

    if (loadingBar) loadingBar.classList.remove('active');
    if (loadingMessage) loadingMessage.style.display = 'none';
}


function processAndDisplayReadme(htmlContent) {
    readmeContentDiv.innerHTML = htmlContent;
    sidebarContentDiv.innerHTML = '';
    headingElements = [];
    sidebarLinks = [];

    const showAllLink = document.createElement('a');
    showAllLink.href = '#section-0';
    showAllLink.textContent = 'Show All';
    showAllLink.classList.add('sidebar-show-all');
    showAllLink.addEventListener('click', (event) => {
        event.preventDefault();
        mainReadmeArea.scrollTo({ top: 0, behavior: 'smooth' });
        updateSidebarActiveLink('');
        searchInput.value = '';
        filterSidebarLinks('');
        searchContainer.classList.remove('active');
    });
    sidebarContentDiv.appendChild(showAllLink);
    sidebarLinks.push(showAllLink);

    const headings = readmeContentDiv.querySelectorAll('h1, h2');

    headings.forEach((heading, index) => {
        let id = heading.id || `section-${index}`;
        heading.id = id;
        headingElements.push(heading);

        const sidebarLink = document.createElement('a');
        sidebarLink.href = `#${id}`;
        sidebarLink.textContent = heading.textContent;
        sidebarLink.classList.add('block');
        if (heading.tagName === 'H2') {
            sidebarLink.classList.add('level-2');
        }
        sidebarLink.addEventListener('click', (event) => {
            event.preventDefault();
            scrollToSection(id);
        });
        sidebarContentDiv.appendChild(sidebarLink);
        sidebarLinks.push(sidebarLink);
    });

    addCopyButtonsToCodeBlocks();

    mainReadmeArea.addEventListener('scroll', highlightActiveSection);
    window.addEventListener('resize', highlightActiveSection);
    setTimeout(highlightActiveSection, 100);
}

function addCopyButtonsToCodeBlocks() {
    const codeBlocks = readmeContentDiv.querySelectorAll('pre');

    codeBlocks.forEach(pre => {
        const codeContainer = document.createElement('div');
        codeContainer.style.position = 'relative';
        codeContainer.style.marginBottom = '1em';

        pre.parentNode.insertBefore(codeContainer, pre);
        codeContainer.appendChild(pre);

        const copyButton = document.createElement('button');
        copyButton.innerHTML = `<svg class="copy-svg" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#a0a0a0" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect class="cop" x="10" y="6"  rx="2" ry="2"/>
  <rect class="cop" x="6" y="3"  rx="2" ry="2"/>
</svg>`;
        copyButton.classList.add('copy-button');

        copyButton.addEventListener('click', async () => {
            const code = pre.querySelector('code');
            if (code) {
                try {
                    await navigator.clipboard.writeText(code.textContent);
                    copyButton.textContent = 'Copied!';
                    setTimeout(() => {
                        copyButton.innerHTML = `<svg class="copy-svg" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#a0a0a0" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="10" y="6" width="12" height="16" rx="2" ry="2"/>
  <rect x="6" y="3" width="12" height="16" rx="2" ry="2"/>
</svg>`;
                    }, 2000);
                } catch (err) {
                    console.error('Failed to copy text: ', err);
                    copyButton.textContent = 'Error';
                }
            }
        });
        codeContainer.appendChild(copyButton);
    });
}


function scrollToSection(sectionId) {
    const targetElement = document.getElementById(sectionId);
    if (targetElement) {
        targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });

        updateSidebarActiveLink(sectionId);
        setTimeout(highlightActiveSection, 300);
    }
}

function highlightActiveSection() {
    const currentScrollPos = mainReadmeArea.scrollTop;
    const offset = 80;

    let activeSectionId = '';

    for (let i = headingElements.length - 1; i >= 0; i--) {
        const heading = headingElements[i];
        if (currentScrollPos + offset >= heading.offsetTop) {
            activeSectionId = heading.id;
            break;
        }
    }
}

function updateSidebarActiveLink(activeSectionId) {
    sidebarLinks.forEach(link => {
        link.classList.remove('active');
    });

    if (activeSectionId) {
        const activeLinked = sidebarContentDiv.querySelector(`a[href="#${activeSectionId}"]`);
        if (activeLinked) {
            activeLinked.classList.add('active');
        }
    }
}

function toggleSearchBar() {
    searchContainer.classList.toggle('active');
    if (searchContainer.classList.contains('active')) {
        searchInput.focus();
    } else {
        searchInput.value = '';
        filterSidebarLinks('');
    }
}

function filterSidebarLinks(query) {
    const lowerCaseQuery = query.toLowerCase().trim();
    const showAllLink = sidebarContentDiv.querySelector('.sidebar-show-all');

    sidebarLinks.forEach(link => {
        if (link === showAllLink) {
            return;
        }

        const linkText = link.textContent.toLowerCase();
        if (lowerCaseQuery === '' || linkText.includes(lowerCaseQuery)) {
            link.style.display = 'block';
        } else {
            link.style.display = 'none';
        }
    });

    if (showAllLink) {
        if (lowerCaseQuery !== '') {
            showAllLink.style.display = 'none';
        } else {
            showAllLink.style.display = 'block';
        }
    }
}

searchToggleButton.addEventListener('click', toggleSearchBar);
searchInput.addEventListener('input', (event) => {
    filterSidebarLinks(event.target.value);
});

document.addEventListener('DOMContentLoaded', fetchReadme);