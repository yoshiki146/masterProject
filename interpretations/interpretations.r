# DI-based methods----------------------------------------------------------

## Recall that we estimate factors for each window, i.e. interpretations may differ for different windows,
## We therefore look at all the factors at the same time to see if which variable are explained well by factors,
## and whose variances are not well captured by factors. This is done by regressing each variables onto 
## the estimated factors. (see also Section 4.2 of the thesis)

### see characterisctics by variables group 
grp <- scan("txt/groups.txt", what=character(),quiet=T)
cols <- scan("txt/targetVariablesShort.txt", what=character(), quiet=T)
## define function to take sparsity ratio averaged by variable group (Table 6 & 7)
collapseCoef <- function(h=1:3,v=1:20,m=c(LASSOcoefs,ENETcoefs,gLASSOcoefs, DICVr2,DILASSOr2)){
  coefs <- m
  collapsed <- coefs[[v]][[h]] %>% 
    as.data.frame %>% 
    rownames_to_column("winID") %>% 
    gather("winID") %>%
    set_colnames(c("winID","varID", "selected")) %>% 
    arrange(winID)
  return(collapsed$selected)  
}

### DICV 
dicvCollapse <- lapply(1:length(targetVariables), function(v){
  data.frame(winID=rep(1:60, each=ncol(dat)), varID=rep(1:(ncol(dat)), winSize), 
             grp=rep(grp, winSize),
             sapply(1:3, collapseCoef, v, DICVr2) %>% set_colnames(c("h1","h3","h12")))
}) %>% set_names(cols)

dicvTable <- lapply(1:length(targetVariables), function(v){
  dicvCollapse[[v]] %>% 
    group_by(grp) %>% 
    summarise_at(c("h1","h3","h12"),funs(mean)) %>% 
    as.data.frame %>% column_to_rownames("grp")
}) %>% set_names(cols)

dicvTable2 <- sapply(dicvTable, function(x) {apply(x,1,mean)}) # Table 7


DICVr2_avg<- sapply(DICVr2, function(v){
  apply(matrix(apply(sapply(v, function(x) x),1,mean),nrow=60),2,mean)
}) %>% as.data.frame 

p1 <- ggplot(DICVr2_avg, aes(1:127,CPI)) + # Figure 2
  geom_bar(stat="identity") +
  labs(x="DICV", y=expression(R^2))

### DILASSO 

dilassoCollapse <- lapply(1:length(targetVariables), function(v){
  data.frame(winID=rep(1:60, each=ncol(dat)), varID=rep(1:(ncol(dat)), winSize),
             grp=rep(grp, winSize),
             sapply(1:3, collapseCoef, v, DILASSOr2) %>% set_colnames(c("h1","h3","h12")))
}) %>% set_names(cols)

dilassoTable <- lapply(1:length(targetVariables), function(v){
  dilassoCollapse[[v]] %>% 
    group_by(grp) %>% 
    summarise_at(c("h1","h3","h12"),funs(mean)) %>% 
    as.data.frame %>% column_to_rownames("grp")
}) %>% set_names(cols)

dilassoTable2 <- sapply(dilassoTable, function(x) {apply(x,1,mean)}) # Table 7

DILASSOr2_avg<- sapply(DILASSOr2, function(v){ # Figure 2
  apply(matrix(apply(sapply(v, function(x) x),1,mean),nrow=60),2,mean)
}) 

p2 <- ggplot(as.data.frame(DILASSOr2_avg), aes(1:127,CPI)) + # Figure 2 
  geom_bar(stat="identity") +
  labs(x="DILASSO", y="") 

gridExtra::arrangeGrob(p1,p2, nrow=1) %>% 
  ggsave("results/fig2.eps", .,  device = "eps")

# VAR / lasso-based methods -----------------------------------------------
## Explore the sparcity ratio (how often the variables are selected) 
## in terms of the groups the variables belong.


### lasso (Table 6)
lassoCollapse <- lapply(1:length(targetVariables), function(v){
  data.frame(winID=rep(1:60, each=ncol(dat)*4), varID=rep(1:(ncol(dat)*4), winSize), 
             grp=rep(grp, winSize), lag=rep(1:4,each=ncol(dat)),
             grpLag=paste(rep(grp, winSize),"_lag",rep(1:3,each=ncol(dat)),sep=""),
             sapply(1:3, collapseCoef, v, m=LASSOcoefs) %>% set_colnames(c("h1","h3","h12")))
}) %>% set_names(cols)

lassoTable <- lapply(1:length(targetVariables), function(v){
  lassoCollapse[[v]] %>% 
    group_by(grp) %>% 
    summarise_at(c("h1","h3","h12"),funs(mean)) %>% 
    as.data.frame %>% column_to_rownames("grp")
}) %>% set_names(cols)

lassoTable2 <- sapply(lassoTable, function(x) {apply(x,1,mean)})


### ENET (Table 6)
enetCollapse <- lapply(1:length(targetVariables), function(v){
  data.frame(winID=rep(1:60, each=ncol(dat)*4), varID=rep(1:(ncol(dat)*4), winSize),
             grp=rep(grp, winSize), lag=rep(1:4,each=ncol(dat)),
             grpLag=paste(rep(grp, winSize),"_lag",rep(1:3,each=ncol(dat)),sep=""),
             sapply(1:3, collapseCoef, v, m=ENETcoefs) %>% set_colnames(c("h1","h3","h12")))
}) %>% set_names(cols)

enetTable <- lapply(1:length(targetVariables), function(v){
  enetCollapse[[v]] %>% 
    group_by(grp) %>% 
    summarise_at(c("h1","h3","h12"),funs(mean)) %>% 
    as.data.frame %>% column_to_rownames("grp")
}) %>% set_names(cols)
enetTable2 <- sapply(enetTable, function(x) {apply(x,1,mean)})

### glasso (Table 6)
glassoCollapse <- lapply(1:length(targetVariables), function(v){
  data.frame(winID=rep(1:60, each=ncol(dat)*4), varID=rep(1:(ncol(dat)*4), winSize),
             grp=rep(grp, winSize), lag=rep(1:4,each=ncol(dat)),
             grpLag=paste(rep(grp, winSize),"_lag",rep(1:3,each=ncol(dat)),sep=""),
             sapply(1:3, collapseCoef, v, m=gLASSOcoefs) %>% set_colnames(c("h1","h3","h12")))
}) %>% set_names(cols)

glassoTable <- lapply(1:length(targetVariables), function(v){
  glassoCollapse[[v]] %>% 
    group_by(grp) %>% 
    summarise_at(c("h1","h3","h12"),funs(mean)) %>% 
    as.data.frame %>% column_to_rownames("grp")
}) %>% set_names(cols)

glassoTable2 <- sapply(glassoTable, function(x) {apply(x,1,mean)})
